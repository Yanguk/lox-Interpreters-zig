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
    lexeme: ?[]u8 = null,
    literal: ?[]u8 = null,
    line: usize,
};

pub const Scanner = struct {
    allocator: std.mem.Allocator,
    source: []u8,
    tokens: std.ArrayList(Token),

    start: usize = 0,
    current: usize = 0,
    line: usize = 1,

    pub fn init(source: []u8, allocator: std.mem.Allocator) Scanner {
        return Scanner{ .source = source, .allocator = allocator, .tokens = .empty };
    }

    pub fn deInit(self: *Scanner) void {
        self.tokens.deinit(self.allocator);
    }

    pub fn scanTokens(self: *Scanner) ![]Token {
        while (!self.isAtEnd()) {
            self.start = self.current;
            try self.scanToken();
        }

        try self.tokens.append(self.allocator, .{
            .type = TokenType.Eof,
            .line = self.line,
        });

        return self.tokens.items;
    }

    fn scanToken(self: *Scanner) !void {
        const char = self.advance();

        switch (char) {
            '(' => try self.addToken(TokenType.LeftParen),
            ')' => try self.addToken(TokenType.RightParen),
            '{' => try self.addToken(TokenType.LeftBrace),
            '}' => try self.addToken(TokenType.RightBrace),
            ',' => try self.addToken(TokenType.Comma),
            '-' => try self.addToken(TokenType.Minus),
            '+' => try self.addToken(TokenType.Plus),
            ';' => try self.addToken(TokenType.Semicolon),
            '*' => try self.addToken(TokenType.Star),
            '!' => try self.addToken(if (self.match('=')) TokenType.BangEqual else TokenType.Bang),
            else => {},
        }
    }

    fn match(self: *Scanner, char: u8) bool {
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

    fn isAtEnd(self: *Scanner) bool {
        return self.current >= self.source.len;
    }

    fn advance(self: *Scanner) u8 {
        const ch = self.source[self.current];
        self.current += 1;

        return ch;
    }

    fn addToken(self: *Scanner, tokenType: TokenType) !void {
        try self.tokens.append(self.allocator, .{
            .type = tokenType,
            .line = self.line,
        });
    }
};

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "Scan TokenType" {
    const gpa = std.testing.allocator;

    var source = [_]u8{ '(', ')', '{', '}', ',', '-', '+', ';', '*', '!', '=' };

    var scanner = Scanner.init(source[0..], gpa);
    defer scanner.deInit();

    const tokens = try scanner.scanTokens();

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

    // line도 확인
    for (tokens) |token| {
        try expectEqual(@as(usize, 1), token.line);
    }
}
