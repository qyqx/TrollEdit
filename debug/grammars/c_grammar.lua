-- C grammar
--
-- TODO:
-- preprocessing instructuions anywhere?
-- enumeration constant?

-- BUGS:
-- (j)++ crashes

-- important constants for Analyzer class
extension = "c"
full_grammar = "program"
other_grammars = {
	block="in_block", 
	translation_unit="top_element"
}
paired = {"{", "}", "(", ")", "[", "]", }

require 'lpeg'

--patterns
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V
--captures
local C, Ct, Cc = lpeg.C, lpeg.Ct, lpeg.Cc

-- nonterminal, general node
function N(arg)
return Ct(
	Cc(arg) *
	V(arg)
	)
end

-- nonterminal, ignored in tree
function NI(arg)
return
	V(arg)
end

-- terminal, text node
function T(arg)
return
	Ct(C(arg)) *
	WC()
end

-- terminal, keyword text node
function TK(arg)
return
	Ct(
	Cc("keyword") *
	T(arg))
end

-- terminal, comment node
function TC(arg)
return
	Ct(C(arg)) *
	N'whites'^-1
end

-- terminal, whites and/or comments
function WC()
return
	N'whites'^-1 *
	N'comments'^-1
end

-- ***  GRAMMAR  ****
local grammar = {"S", 

-- ENTRY POINTS
program =  
	Ct(Cc("program") *
	WC() *
	N'translation_unit'^0	*
	N'unknown'^-1 *-1),
top_element =  
	Ct(
	WC() *
	N'translation_unit'^0 *
	N'unknown'^-1 *-1),
in_block = 
	Ct (
	WC() *
	N'block'^-1 *
	N'unknown'^-1),

-- NONTERMINALS
translation_unit = N'preprocessor' + N'funct_definition' + N'declaration',

preprocessor = (NI'include' + ((TK"#define" + TK"#elif" + TK"#else" + TK"#endif" +
	TK"#error" + TK"#ifdef" + TK"#ifndef" + TK"#if" + TK"#import" + TK"#include" + TK"#line" +
	TK"#pragma" + TK"#undef") * T((1 - P"\n")^0))),
	
include = TK"#include" * T"<" * T((1 - P">")^1) * T">",

funct_definition =
	NI'declaration_specifiers'^-1 * N'declarator' *N'declaration'^0 * T"{" * N'block' * T"}",

declaration =  NI'declaration_specifiers' * N'init_declarator' * (T"," * N'init_declarator')^0 * T";",

declaration_specifiers =
	NI'declaration_class_qualifier'^0 * N'type_specifier' * NI'declaration_class_qualifier'^0,

declaration_class_qualifier = N'storage_class_specifier' + N'type_qualifier',

storage_class_specifier =
	TK"auto" + TK"register" + TK"static" + TK"extern" + TK"typedef",

type_specifier = 
	(TK"void" + TK"char" + TK"short" + TK"int" + TK"long" + TK"float" +
	TK"double" + TK"signed" + TK"unsigned" + N'struct_or_union_specifier' +
	N'enum_specifier' + N'typedef_name'
	),

type_qualifier =  (TK"const" + TK"volatile"),

struct_or_union_specifier =
	(TK"struct" + TK"union") * 
	(N'identifier'^-1 * T"{" * N'struct_declaration'^1 * T"}" +
	N'identifier'
	),

init_declarator =
	N'declarator' * (T"=" * N'initializer')^-1,

struct_declaration =
-- 	(N'type_specifier' + N'type_qualifier')^1 * --TODO
	N'type_specifier' *
	N'struct_declarator' * (T"," * N'struct_declarator')^0 * T";",

struct_declarator =  N'declarator' + (N'declarator'^-1 * T":" * N'constant_expression'),

enum_specifier =  
	TK"enum" * (N'identifier' + N'identifier'^-1 *
	T"{" * N'enumerator' * (T"," * N'enumerator')^0 * T"}"),

enumerator =  N'identifier' * (T"=" * N'constant_expression')^-1,

declarator =
	N'pointer'^-1 * (N'identifier' + T"(" * N'declarator' * T")") * (
	T"[" * N'constant_expression'^-1 * T"]" +
	T"(" * N'parameter_type_list' * T")" +
	T"(" * (N'identifier' * (T"," * N'identifier')^0)^-1 * T")"
	)^0,

pointer = (T"*" * N'type_qualifier'^0)^1,

parameter_type_list =  N'parameter_declaration' * (T"," * N'parameter_declaration')^0 * (T"," * T"...")^-1,

parameter_declaration =
	N'declaration_specifiers' * (N'declarator' + N'abstract_declarator')^-1,

initializer =  N'assignment_expression' + 
	T"{" * N'initializer' * (T"," * N'initializer')^0 * T","^-1* T"}",

type_name =  (N'type_specifier' + N'type_qualifier')^1 * N'abstract_declarator'^-1,

abstract_declarator =
	N'pointer'^-1 * (T"(" * N'abstract_declarator' * T")")^-1 * (
	T"[" * N'constant_expression'^-1 * T"]" +
	T"(" * N'parameter_type_list'^-1 * T")"
	)^0,
	
statement =
-- 	((N'identifier' + TK"case" * N'constant_expression' + TK"default") * T":")^0 * 
	(N'expression'^-1 * T";" +
	T"{" * N'block' * T"}" +
	TK"if" * T"(" * N'expression' * T")" * N'statement' * TK"else" * N'statement' +
	TK"if" * T"(" * N'expression' * T")" * N'statement' +
	TK"switch" * T"(" * N'expression' * T")" * T"{" * N'case_statement'^0 * T"}" +
	TK"while" * T"(" * N'expression' * T")" * N'statement' +
	TK"do" * N'statement' * T"while" * T"(" * N'expression' * T")" * T";" +
	TK"for" * T"(" * N'expression'^-1 * T";" * N'expression'^-1 * T";" * N'expression'^-1 * T")" * N'statement' +
	TK"goto" * N'identifier' * T";" +
	TK"continue" * T";" +
	TK"break" * T";" +
	TK"return" * N'expression'^-1 * T";"
	),

block =  (N'declaration' + N'statement' + N'preprocessor')^0,

case_statement = 
	(N'identifier' + TK"case" * N'constant_expression' + TK"default") * T":" * N'statement'^0,

expression =
	NI'assignment_expression' * (T"," * NI'assignment_expression')^0,

assignment_expression =  (
	NI'unary_expression' * (
	T"*=" + T"/=" + T"%=" + T"+=" + T"-=" + T"<<=" + T">>=" + T"&=" + (T"=" *-P"=") +
	T"^=" + T"|="))^0 * NI'conditional_expression',

conditional_expression =
	NI'simple_expression' * (T"?" * NI'expression' * T":" * NI'conditional_expression')^-1,

constant_expression =  NI'conditional_expression',

simple_expression = NI'cast_expression' * ((
	T"*" + T"/" + T"%" + T"+" + T"-" + T"<<" + T">>" + T"<=" + T">=" + T"<" + T">" + 
	T"==" + T"!=" + T"&&"+ T"&" + T"||" + T"|" + T"^"
	) * NI'cast_expression')^0,

cast_expression =
	N'cast'^0 * NI'unary_expression',
	
cast = T"(" * NI'type_name' * T")",

unary_expression =
	(T"++" + T"--" + TK"sizeof")^0 * (
	TK"sizeof" * T"(" * NI'type_name' * T")" +
	(T"&" + T"*" + T"+" + T"-" + T"~" + T"!") * NI'cast_expression' +
	NI'postfix_expression'
	),

postfix_expression =
	(N'funct_call' + N'identifier' + NI'constant' +
	T"(" * NI'expression' * T")") * (
	T"[" * NI'expression' * T"]" +
	T"." * NI'identifier' +
	T"->" * NI'identifier' +
	T"++" + T"--")^0,

funct_call = N'identifier' * T"(" * (N'funct_param' * (T"," * N'funct_param')^0)^-1 * T")",

funct_param = NI'assignment_expression',

constant =
	N'number_constant' +
	N'character_constant' +
	N'string_constant' --+
	-- N'enumeration_constant'
	,

comments = (N'doc_comment' + N'multi_comment' + N'line_comment')^1,

-- TERMINALS
number_constant = NI'number_literal',
character_constant = NI'character_literal',
string_constant = NI'string_literal',
-- enumeration_constant = , -- TODO
identifier = NI'identifier_name',
typedef_name = NI'identifier_name',

doc_comment = TC(P"/**" * (1 - P"*/")^0 * P"*/"),
multi_comment = TC(P"/*" * (1 - P"*/")^0 * P"*/"),
line_comment = TC(P"//" * (1 - P"\n")^0),

unknown = Ct(C(P(1)^1)), -- anything

-- LITERALS
whites = Ct(C(S(" \t\n")^1)),

digit = R"09",
hex = R("af", "AF", "09"),
e = S"eE" * S"+-"^-1 * NI'digit'^1,
fs = S"fFlL",
is = S"uUlL"^0,
hexnum = P"0" * S"xX" * NI'hex'^1 * NI'is'^-1,
octnum = P"0" * NI'digit'^1 * NI'is'^-1,
decnum = NI'digit'^1 * NI'is'^-1,
floatnum = NI'digit'^1 * NI'e' * NI'fs'^-1 +
	NI'digit'^0 * P"." * NI'digit'^1 * NI'e'^-1 * NI'fs'^-1 +
	NI'digit'^1 * P"." * NI'digit'^0 * NI'e'^-1 * NI'fs'^-1,
		 
number_literal = T(NI'hexnum' + NI'octnum' + NI'floatnum' + NI'decnum'),
character_literal = T(P"L"^-1 * P"'" * (P"\\" * P(1) + (1 - S"\\'"))^1 * P"'"),
string_literal = T(P"L"^-1 * P'"' * (P"\\" * P(1) + (1 - S'\\"'))^0 * P'"'),

letter = R("az", "AZ") + P"_",
alnum = NI'letter' + NI'digit',
keyword =
	P"auto" + P"break" + P"case" + P"char" + P"const" +
	P"continue" + P"default" + P"do" + P"double" + P"else" + P"enum" + P"extern" +
	P"float" + P"for" + P"goto" + P"if" + P"inline" + P"int" + P"long" +
	P"register" + P"restrict" + P"return" + P"short" + P"signed" + P"sizeof" + P"static" +
	P"struct" + P"switch" + P"typedef" + P"union" + P"unsigned" + P"void" + P"volatile" +
	P"while",
identifier_name = T(NI'letter' * NI'alnum'^0 - NI'keyword' * (-NI'alnum')),
} 
-- ***  END OF GRAMMAR  ****

-- *** POSSIBLE GRAMMARS (ENTRY POINTS) ****
grammar[1] = "program"
program = P(grammar)
grammar[1] = "top_element"
top_element = P(grammar)
grammar[1] = "in_block"
in_block = P(grammar)

--*******************************************************************
-- TESTING - this script cannot be used by Analyzer.cpp when these lines are uncommented !!!

-- dofile('default_grammar.lua')
-- test("../input.c", program)
