enum ZValue<'a> {
    Seq(Vec<ZValue<'a>>),
    Dict(Map<&str, ZValue<'a>>),
    MacroAA(),
    MacroAB(),
    MacroBB()
}

trait MacroAA {
    fn eval<'a>(&self, lexemes: Vec<ZLexeme<'a>>) -> Vec<ZLexeme<'a>>;
}

trait MacroAB {
    fn eval<'a>(&self, lexemes: Vec<ZLexeme<'a>>) -> ZValue<'a>;
}

trait MacroBB {
    fn eval<'a>(&self, value: ZValue<'a>) -> ZValue<'a>;
}

struct ContextB<'a> {
    env: Map<&'a str, ZValue<'a>>
}

impl ContextB {
    fn eval<'a>(self, lexemes: Vec<ZLexeme<'a>>) -> (ContextB, ZValue<'a>) {
    }
}
