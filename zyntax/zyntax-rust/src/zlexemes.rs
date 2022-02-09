use super::lexing::LexemeExtractor;

use std::char;
use std::fmt::Debug;

#[derive(Debug, Clone)]
pub(crate) enum ZLexeme<'a> {
    Id(&'a str),
    Number(&'a str),
    String(&'a str),
    Open(&'a str),
    Close(char),
}

pub(crate) struct ZIdExtractor {
    regex: &'static str,
}

impl ZIdExtractor {
    pub(crate) fn new() -> Self {
        ZIdExtractor {
            regex: r#"(?:\p{L}|\p{S})\p{M}*(?:[^\p{Z}\p{Ps}\p{Pe}\p{C}]\p{M}*)*"#,
        }
    }
}

impl<'a> LexemeExtractor<'a, ZLexeme<'a>> for ZIdExtractor {
    fn regex<'s>(&'s self) -> &'s str {
        self.regex
    }

    fn extract(&self, s: &'a str) -> Option<ZLexeme<'a>> {
        Some(ZLexeme::Id(s))
    }
}

pub(crate) struct ZNumberExtractor {
    regex: &'static str,
}

impl ZNumberExtractor {
    pub(crate) fn new() -> Self {
        ZNumberExtractor {
            regex: r#"-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][-+][0-9]*)?"#,
        }
    }
}

impl<'a> LexemeExtractor<'a, ZLexeme<'a>> for ZNumberExtractor {
    fn regex<'s>(&'s self) -> &'s str {
        self.regex
    }

    fn extract(&self, s: &'a str) -> Option<ZLexeme<'a>> {
        Some(ZLexeme::Number(s))
    }
}

pub(crate) struct ZStringExtractor {
    regex: &'static str,
}

impl ZStringExtractor {
    pub(crate) fn new() -> Self {
        ZStringExtractor {
            regex: r#""[^"]*""#,
        }
    }
}

impl<'a> LexemeExtractor<'a, ZLexeme<'a>> for ZStringExtractor {
    fn regex<'s>(&'s self) -> &'s str {
        self.regex
    }

    fn extract(&self, s: &'a str) -> Option<ZLexeme<'a>> {
        Some(ZLexeme::String(s))
    }
}

pub(crate) struct ZWhitespaceExtractor {
    regex: &'static str,
}

impl ZWhitespaceExtractor {
    pub(crate) fn new() -> Self {
        ZWhitespaceExtractor {
            regex: r#"[\p{Z}\p{C}]+"#,
        }
    }
}

impl<'a> LexemeExtractor<'a, ZLexeme<'a>> for ZWhitespaceExtractor {
    fn regex<'s>(&'s self) -> &'s str {
        self.regex
    }

    fn extract(&self, _s: &'a str) -> Option<ZLexeme<'a>> {
        None
    }
}

pub(crate) struct ZOpenExtractor {
    regex: &'static str,
}

impl ZOpenExtractor {
    pub(crate) fn new() -> Self {
        ZOpenExtractor {
            regex: r#"(?:[^\p{Z}\p{Ps}\p{Pe}\p{C}]\p{M}*)*\p{Ps}"#,
        }
    }
}

impl<'a> LexemeExtractor<'a, ZLexeme<'a>> for ZOpenExtractor {
    fn regex<'s>(&'s self) -> &'s str {
        self.regex
    }

    fn extract(&self, s: &'a str) -> Option<ZLexeme<'a>> {
        Some(ZLexeme::Open(s))
    }
}

pub(crate) struct ZCloseExtractor {
    regex: &'static str,
}

impl ZCloseExtractor {
    pub(crate) fn new() -> Self {
        ZCloseExtractor { regex: r#"\p{Pe}"# }
    }
}

impl<'a> LexemeExtractor<'a, ZLexeme<'a>> for ZCloseExtractor {
    fn regex<'s>(&'s self) -> &'s str {
        self.regex
    }

    fn extract(&self, s: &'a str) -> Option<ZLexeme<'a>> {
        Some(ZLexeme::Close(s.chars().next().unwrap()))
    }
}
