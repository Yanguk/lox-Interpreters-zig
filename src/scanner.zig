const std = @import("std");

pub const TokenType = enum {
    // Single-character tokens.
    LeftParen,
    RightParen,
    LeftBrace,
    RightBrace,
    Comma,
    Dot,
    Minus,
    Plus,
    Semicolon,
    Slash,
    Star,

    // One or two character tokens.
    Bang,
    BangEqual,
    Equal,
    EqualEqual,
    Greater,
    GreaterEqual,
    Less,
    LessEqual,

    // Literals.
    Identifier,
    String,
    Number,

    // Keywords.
    And,
    Class,
    Else,
    False,
    For,
    Fun,
    If,
    Nil,
    Or,
    Print,
    Return,
    Super,
    This,
    True,
    Var,
    While,
    Error,
    Eof,
};

const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: usize,
};

const TokenIter = struct {
    source: []const u8,

    start: usize = 0,
    current: usize = 0,
    line: usize = 1,

    finished: bool = false,

    pub fn next(self: *TokenIter) ?Token {
        if (self.finished) {
            return null;
        }

        self.skipTrivia();
        self.start = self.current;

        if (self.isAtEnd()) {
            self.finished = true;

            return self.makeToken(.Eof);
        }

        const char = self.advance();

        return switch (char) {
            '(' => self.makeToken(.LeftParen),
            ')' => self.makeToken(.RightParen),
            '{' => self.makeToken(.LeftBrace),
            '}' => self.makeToken(.RightBrace),
            ',' => self.makeToken(.Comma),
            '-' => self.makeToken(.Minus),
            '+' => self.makeToken(.Plus),
            ';' => self.makeToken(.Semicolon),
            '*' => self.makeToken(.Star),
            '!' => self.makeToken(if (self.match('=')) .BangEqual else .Bang),
            '/' => self.makeToken(.Slash),
            '"' => self.string(),
            else => self.makeError("Unexpected character."),
        };
    }

    fn string(self: *TokenIter) Token {
        while (self.peek() != '"' and !self.isAtEnd()) {
            _ = self.advance();
        }

        if (self.isAtEnd()) {
            return self.makeError("Unterminated string.");
        }

        const lexeme = self.source[self.start + 1 .. self.current - 1];

        return Token{
            .type = .String,
            .lexeme = lexeme,
            .line = self.line,
        };
    }

    fn skipTrivia(self: *TokenIter) void {
        while (true) {
            const char = self.peek();

            switch (char) {
                '\r', '\t', ' ' => {
                    _ = self.advance();
                },
                '\n' => {
                    self.line += 1;
                    _ = self.advance();
                },
                '/' => {
                    if (self.peekNext() == '/') {
                        while (self.peek() != '\n' and !self.isAtEnd()) {
                            _ = self.advance();
                        }
                    }
                },
                else => return,
            }
        }
    }

    fn makeToken(self: *TokenIter, typ: TokenType) Token {
        return Token{
            .type = typ,
            .line = self.line,
            .lexeme = self.source[self.start..self.current],
        };
    }

    fn makeError(self: *TokenIter, messages: []const u8) Token {
        return Token{
            .type = .Error,
            .line = self.line,
            .lexeme = messages,
        };
    }

    fn peek(self: *TokenIter) u8 {
        return if (self.isAtEnd()) '\x00' else self.source[self.current];
    }

    fn peekNext(self: *TokenIter) u8 {
        return if (self.current + 1 >= self.source.len) 0 else self.source[self.current + 1];
    }

    fn match(self: *TokenIter, char: u8) bool {
        if (self.isAtEnd()) {
            return false;
        }

        const current = self.source[self.current];

        const is_match = current == char;

        if (is_match) {
            self.current += 1;
        }

        return is_match;
    }

    fn isAtEnd(self: *TokenIter) bool {
        return self.current >= self.source.len;
    }

    fn advance(self: *TokenIter) u8 {
        const ch = self.source[self.current];
        self.current += 1;

        return ch;
    }
};

pub fn scan(source: []const u8) TokenIter {
    return TokenIter{ .source = source };
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;
const expectEqualStrings = std.testing.expectEqualStrings;

test "Scan TokenType" {
    const gpa = std.testing.allocator;

    const source =
        \\ (){ }, //주석
        \\ -+;*!=
    ;

    var tokenIter = scan(source[0..]);

    var tokenArray: std.ArrayList(Token) = .empty;
    defer tokenArray.deinit(gpa);

    while (tokenIter.next()) |token| {
        try tokenArray.append(gpa, token);
    }

    const tokens = tokenArray.items;

    for (tokens) |token| {
        std.debug.print(
            "DEBUG_💥[{s}:{d}]: token={any}\n, lexeme=\"{s}\"\n",
            .{ @src().file, @src().line, token, token.lexeme },
        );
    }

    // 마지막 EOF까지 포함
    try expectEqual(@as(usize, 11), tokens.len);
    try expectEqual(TokenType.LeftParen, tokens[0].type);
    try expectEqual(TokenType.RightParen, tokens[1].type);
    try expectEqual(TokenType.LeftBrace, tokens[2].type);
    try expectEqual(TokenType.RightBrace, tokens[3].type);
    try expectEqual(TokenType.Comma, tokens[4].type);
    try expectEqual(TokenType.Minus, tokens[5].type);
    try expectEqual(TokenType.Plus, tokens[6].type);
    try expectEqual(TokenType.Semicolon, tokens[7].type);
    try expectEqual(TokenType.Star, tokens[8].type);
    try expectEqual(TokenType.BangEqual, tokens[9].type);
    try expectEqual(TokenType.Eof, tokens[10].type);

    try expectEqualStrings("!=", tokens[9].lexeme);
    try expectEqualStrings("", tokens[10].lexeme);
}
