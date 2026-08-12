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

const keywords = std.StaticStringMap(TokenType).initComptime(.{
    .{ "and", .And },
    .{ "class", .Class },
    .{ "else", .Else },
    .{ "false", .False },
    .{ "for", .For },
    .{ "fun", .Fun },
    .{ "if", .If },
    .{ "nil", .Nil },
    .{ "or", .Or },
    .{ "print", .Print },
    .{ "return", .Return },
    .{ "super", .Super },
    .{ "this", .This },
    .{ "true", .True },
    .{ "var", .Var },
    .{ "while", .While },
});

const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    line: usize,
};

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn isAlpha(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
}

fn isAlphaNumeric(c: u8) bool {
    return isAlpha(c) or isDigit(c);
}

const TokenIter = struct {
    source: []const u8,

    start: usize = 0,
    current: usize = 0,
    line: usize = 1,

    eof_emitted: bool = false,

    pub fn next(self: *TokenIter) ?Token {
        if (self.eof_emitted) {
            return null;
        }

        self.skipTrivia();
        self.start = self.current;

        if (self.isAtEnd()) {
            self.eof_emitted = true;

            return self.makeToken(.Eof);
        }

        const c = self.advance();

        return switch (c) {
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
            '=' => self.makeToken(if (self.match('=')) .EqualEqual else .Equal),
            '<' => self.makeToken(if (self.match('=')) .LessEqual else .Less),
            '>' => self.makeToken(if (self.match('=')) .GreaterEqual else .Greater),
            '/' => self.makeToken(.Slash),
            '"' => self.string(),
            else => {
                if (isDigit(c)) {
                    return self.number();
                }

                if (isAlpha(c)) {
                    return self.identifier();
                }

                return self.makeError("Unexpected character.");
            },
        };
    }

    fn number(self: *TokenIter) Token {
        while (isDigit(self.peek())) {
            _ = self.advance();
        }

        if (self.peek() == '.' and isDigit(self.peekNext())) {
            // Consume the "."
            _ = self.advance();

            while (isDigit(self.peek())) {
                _ = self.advance();
            }
        }

        const lexeme = self.source[self.start..self.current];

        return Token{
            .type = .Number,
            .lexeme = lexeme,
            .line = self.line,
        };
    }

    fn identifier(self: *TokenIter) Token {
        while (isAlphaNumeric(self.peek())) {
            _ = self.advance();
        }

        const lexeme = self.source[self.start..self.current];

        const ty = keywords.get(lexeme) orelse .Identifier;

        return Token{
            .type = ty,
            .lexeme = lexeme,
            .line = self.line,
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
        return if (self.isAtEnd()) 0 else self.source[self.current];
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

test "scan tokens" {
    const source = "var foo = 123;";

    var tokenIter = scan(source);

    const token1 = tokenIter.next() orelse unreachable;
    try std.testing.expectEqual(TokenType.Var, token1.type);

    const token2 = tokenIter.next() orelse unreachable;
    try std.testing.expectEqual(TokenType.Identifier, token2.type);

    const token3 = tokenIter.next() orelse unreachable;
    try std.testing.expectEqual(TokenType.Equal, token3.type);

    const token4 = tokenIter.next() orelse unreachable;
    try std.testing.expectEqual(TokenType.Number, token4.type);

    const token5 = tokenIter.next() orelse unreachable;
    try std.testing.expectEqual(TokenType.Semicolon, token5.type);

    const token6 = tokenIter.next() orelse unreachable;
    try std.testing.expectEqual(TokenType.Eof, token6.type);
}
