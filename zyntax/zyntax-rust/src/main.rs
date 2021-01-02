mod lexing;
mod zlexemes;

use itertools::Itertools;

use lexing::{parse, LexemeExtractor};

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
    println!();
}
