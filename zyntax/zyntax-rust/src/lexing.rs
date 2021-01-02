use itertools::Itertools;
use regex::Regex;
use std::fmt::Debug;

pub(crate) trait LexemeExtractor<'a, T> {
    fn regex<'s>(&'s self) -> &'s str;
    fn extract(&self, s: &'a str) -> Option<T>;
}

// https://stackoverflow.com/questions/61446984/impl-iterator-failing-for-iterator-with-multiple-lifetime-parameters
pub(crate) trait Captures<'a> {}
impl<'a, T: ?Sized> Captures<'a> for T {}

#[derive(Debug, Clone, Copy)]
pub(crate) struct Pos {
    line: usize,
    column: usize,
}

#[derive(Debug)]
pub(crate) struct PosAware<T> {
    pub value: T,
    pub start: Pos,
    pub end: Pos,
}

pub(crate) fn parse<'a, 'b, T>(
    extractors: &'b Vec<Box<dyn LexemeExtractor<'a, T>>>,
    code: &'a str,
) -> impl Iterator<Item = PosAware<T>> + Captures<'a> + 'b {
    let common_pattern: String = extractors
        .iter()
        .map(|ex| format!(r#"(^{})"#, ex.regex()))
        .join("|");
    let re: Regex = Regex::new(common_pattern.as_str()).unwrap();

    let mut pos = Pos { line: 1, column: 1 };

    itertools::unfold(
        code,
        move |rest: &mut &'a str| -> Option<Option<PosAware<T>>> {
            println!("rest: {:?}", rest);
            if rest.is_empty() {
                None
            } else {
                let captures = re.captures(rest).unwrap();
                println!("{:?}", captures);
                let mut it = extractors
                    .iter()
                    .enumerate()
                    .filter_map(|(i, ex)| captures.get(i + 1).map(|c| (ex, c)));
                let (ex, c) = it.next().unwrap();
                assert!(it.next().is_none(), "Captures: {:?}", captures);
                *rest = &rest[c.end()..];

                let opos = pos.clone();

                pos = match c.as_str().rfind("\n") {
                    Some(k) => Pos {
                        line: pos.line + c.as_str().matches("\n").count(),
                        column: c.as_str().len() - k,
                    },
                    None => Pos {
                        line: pos.line,
                        column: pos.column + c.as_str().len(),
                    },
                };

                Some(ex.extract(c.as_str()).map(|v| PosAware {
                    value: v,
                    start: opos,
                    end: pos,
                }))
            }
        },
    )
    .flatten()
}
