mod lexing;
mod zlexemes;

use std::collections::HashMap;
use std::fmt::Debug;
use std::iter::Peekable;
use std::rc::Rc;
use itertools::Itertools;

use lexing::{parse, LexemeExtractor, PosAware};
use zlexemes::ZLexeme;

#[derive(Debug, Clone)]
enum Tree<T> {
    Inner(T, Vec<Tree<T>>),
    Leaf(T),
}

fn treeify<'a>(
    iter: &mut Peekable<impl Iterator<Item = PosAware<ZLexeme<'a>>>>,
) -> Tree<ZLexeme<'a>> {
    match iter.next().unwrap().value {
        ZLexeme::Open(s) => {
            let v: Vec<_> = iter
                .batching(|it| match it.peek().unwrap().value {
                    ZLexeme::Close(_) => { it.next(); None },
                    _ => Some(treeify(it)),
                })
                .collect();
            Tree::Inner(ZLexeme::Open(s), v)
        }
        ZLexeme::Close(s) => panic!("Unexpected closing bracket: {:?}", s),
        lex => Tree::Leaf(lex),
    }
}

#[derive(Debug, Clone)]
enum ZValue<'a> {
    String(&'a str),
    Seq(Vec<ZValue<'a>>),
    Dict(HashMap<&'a str, ZValue<'a>>),
    MacroAA(Rc<dyn MacroAA>),
    MacroAB(Rc<dyn MacroAB>),
    MacroBB(Rc<dyn MacroBB>)
}

trait MacroAA: Debug {
    fn eval<'a>(&self, trees: &[Tree<ZLexeme<'a>>]) -> Tree<ZLexeme<'a>>;
}

#[derive(Debug, Clone)]
struct ReverseAA;

impl MacroAA for ReverseAA {
    fn eval<'a>(&self, trees: &[Tree<ZLexeme<'a>>]) -> Tree<ZLexeme<'a>> {
        println!("reverse in: {:?}", trees);
        Tree::Inner(ZLexeme::Open("("), trees.into_iter().rev().cloned().collect())
    }
}

trait MacroAB: Debug {
    fn eval<'a>(&self, context: &mut ContextB<'a>, trees: &[Tree<ZLexeme<'a>>]) -> ZValue<'a>;
}

#[derive(Debug, Clone)]
struct ListAB;
impl MacroAB for ListAB {
    fn eval<'a>(&self, context: &mut ContextB<'a>, trees: &[Tree<ZLexeme<'a>>]) -> ZValue<'a> {
        ZValue::Seq(trees.into_iter().map(|tree| { context.eval(tree) }).collect())
    }
}

trait MacroBB: Debug {
    fn eval<'a>(&self, value: ZValue<'a>) -> ZValue<'a>;
}

struct ContextB<'a> {
    env: HashMap<&'a str, ZValue<'a>>
}

impl<'a> ContextB<'a> {
    fn new() -> Self {
        ContextB {
            env: vec![
                ("reverse", ZValue::MacroAA(Rc::new(ReverseAA {}))),
                ("list", ZValue::MacroAB(Rc::new(ListAB {})))
            ].into_iter().collect()
        }
    }

    fn eval_seq(&mut self, trees: &[Tree<ZLexeme<'a>>]) -> ZValue<'a> {
        let elements: Vec<ZValue<'a>> = trees.into_iter().map(|tree| {
            self.eval(tree)
        }).collect();

        ZValue::Seq(elements)
    }

    fn eval_dict(&mut self, trees: &[Tree<ZLexeme<'a>>]) -> ZValue<'a> {
        let elements: HashMap<&'a str, ZValue<'a>> = trees.into_iter().tuples().map(|(ktree, vtree)| {
            let key: &'a str = match ktree {
                Tree::Leaf(ZLexeme::Id(id)) => id.strip_prefix(":").unwrap(),
                _ => panic!("Expected :keyword, got {:?}", ktree)
            };
            let value = self.eval(vtree);
            (key, value)
        }).collect();

        ZValue::Dict(elements)
    }

    fn eval_eval(&mut self, trees: &[Tree<ZLexeme<'a>>]) -> ZValue<'a> {
        println!("eval in: {:?}", trees);
        let xxx = self.eval(&trees[0]);

        match xxx {
            ZValue::MacroAA(m) => self.eval(&m.eval(&trees[1..])),
            ZValue::MacroAB(m) => m.eval(self, &trees[1..]),
            ZValue::MacroBB(m) => m.eval(self.eval_eval(&trees[1..])),
            _ => panic!("Don't know how to evaluate {:?}", xxx)
        }
    }

    fn eval_id(&mut self, id: &'a str) -> ZValue<'a> {
        self.env.get(id).expect("Identifier not found").clone()
    }

    fn eval_string(&self, s: &'a str) -> ZValue<'a> {
        ZValue::String(s.strip_prefix('"').unwrap().strip_suffix('\"').unwrap())
    }

    fn eval(&mut self, tree: &Tree<ZLexeme<'a>>) -> ZValue<'a> {
        match tree {
            Tree::Leaf(ZLexeme::Id(id)) => self.eval_id(id),
            Tree::Leaf(ZLexeme::String(s)) => self.eval_string(s),
            Tree::Inner(ZLexeme::Open(br), subtrees) => {
                match *br {
                    "(" => self.eval_eval(&subtrees),
                    "[" => self.eval_seq(&subtrees),
                    "{" => self.eval_dict(&subtrees),
                    _ => panic!("Cannot evaluate {:?}", tree)
                }
            },
            _ => panic!("Cannot evaluate {:?}", tree)
        }
    }
}

fn main() {
    let extractors: Vec<Box<dyn LexemeExtractor<_>>> = vec![
        Box::new(zlexemes::ZIdExtractor::new()),
        Box::new(zlexemes::ZNumberExtractor::new()),
        Box::new(zlexemes::ZStringExtractor::new()),
        Box::new(zlexemes::ZOpenExtractor::new()),
        Box::new(zlexemes::ZCloseExtractor::new()),
        Box::new(zlexemes::ZWhitespaceExtractor::new()),
    ];

    let tokens: Vec<_> = parse(
        &extractors,
        r#"(foo "bar" [wee 0 -10 21.37e-1])
f(123 456)"#,
    )
    .collect();

    println!("{:?}", tokens.iter().map(|pa| &pa.value).collect_vec());
    println!("{:?}", treeify(&mut tokens.iter().cloned().peekable()));

    let tokens2: Vec<_> = parse(
        &extractors,
        "(reverse [] \"aaa\" list)"
    ).collect();

    println!("{:?}", tokens2.iter().map(|pa| &pa.value).collect_vec());

    let tree2 = treeify(&mut tokens2.iter().cloned().peekable());

    println!("{:?}", tree2);

    let mut contextb = ContextB::new();

    println!("{:?}", contextb.eval(&tree2))
}
