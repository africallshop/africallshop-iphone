/** \file
 *  This C header file was generated by $ANTLR version 3.2 Sep 23, 2009 12:02:23
 *
 *     -  From the grammar source file : /Users/karimjimo/Downloads/linphone-iphone/submodules/build/..//belle-sip/src/belle_sip_message.g
 *     -                            On : 2013-10-13 11:15:15
 *     -                 for the lexer : belle_sip_messageLexerLexer *
 * Editing it, at least manually, is not wise. 
 *
 * C language generator and runtime by Jim Idle, jimi|hereisanat|idle|dotgoeshere|ws.
 *
 *
 * The lexer belle_sip_messageLexer has the callable functions (rules) shown below,
 * which will invoke the code for the associated rule in the source grammar
 * assuming that the input stream is pointing to a token/text stream that could begin
 * this rule.
 * 
 * For instance if you call the first (topmost) rule in a parser grammar, you will
 * get the results of a full parse, but calling a rule half way through the grammar will
 * allow you to pass part of a full token stream to the parser, such as for syntax checking
 * in editors and so on.
 *
 * The parser entry points are called indirectly (by function pointer to function) via
 * a parser context typedef pbelle_sip_messageLexer, which is returned from a call to belle_sip_messageLexerNew().
 *
 * As this is a generated lexer, it is unlikely you will call it 'manually'. However
 * the methods are provided anyway.
 * * The methods in pbelle_sip_messageLexer are  as follows:
 *
 *  -  void      pbelle_sip_messageLexer->T__24(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__25(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__26(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__27(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__28(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__29(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__30(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__31(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__32(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__33(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__34(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__35(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__36(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__37(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__38(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__39(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__40(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__41(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->T__42(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->COMMON_CHAR(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->HEX_CHAR(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->DIGIT(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->CRLF(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->HTAB(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->DQUOTE(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->LWS(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->PLUS(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->COLON(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->SEMI(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->COMMA(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->LAQUOT(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->RAQUOT(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->RPAREN(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->LPAREN(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->EQUAL(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->SLASH(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->STAR(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->SP(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->OCTET(pbelle_sip_messageLexer)
 *  -  void      pbelle_sip_messageLexer->Tokens(pbelle_sip_messageLexer)
 *
 * The return type for any particular rule is of course determined by the source
 * grammar file.
 */
// [The "BSD licence"]
// Copyright (c) 2005-2009 Jim Idle, Temporal Wave LLC
// http://www.temporal-wave.com
// http://www.linkedin.com/in/jimidle
//
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products
//    derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#ifndef	_belle_sip_messageLexer_H
#define _belle_sip_messageLexer_H
/* =============================================================================
 * Standard antlr3 C runtime definitions
 */
#include    <antlr3.h>

/* End of standard antlr 3 runtime definitions
 * =============================================================================
 */
 
#ifdef __cplusplus
extern "C" {
#endif

// Forward declare the context typedef so that we can use it before it is
// properly defined. Delegators and delegates (from import statements) are
// interdependent and their context structures contain pointers to each other
// C only allows such things to be declared if you pre-declare the typedef.
//
typedef struct belle_sip_messageLexer_Ctx_struct belle_sip_messageLexer, * pbelle_sip_messageLexer;



#ifdef	ANTLR3_WINDOWS
// Disable: Unreferenced parameter,							- Rules with parameters that are not used
//          constant conditional,							- ANTLR realizes that a prediction is always true (synpred usually)
//          initialized but unused variable					- tree rewrite variables declared but not needed
//          Unreferenced local variable						- lexer rule declares but does not always use _type
//          potentially unitialized variable used			- retval always returned from a rule 
//			unreferenced local function has been removed	- susually getTokenNames or freeScope, they can go without warnigns
//
// These are only really displayed at warning level /W4 but that is the code ideal I am aiming at
// and the codegen must generate some of these warnings by necessity, apart from 4100, which is
// usually generated when a parser rule is given a parameter that it does not use. Mostly though
// this is a matter of orthogonality hence I disable that one.
//
#pragma warning( disable : 4100 )
#pragma warning( disable : 4101 )
#pragma warning( disable : 4127 )
#pragma warning( disable : 4189 )
#pragma warning( disable : 4505 )
#pragma warning( disable : 4701 )
#endif

/** Context tracking structure for belle_sip_messageLexer
 */
struct belle_sip_messageLexer_Ctx_struct
{
    /** Built in ANTLR3 context tracker contains all the generic elements
     *  required for context tracking.
     */
    pANTLR3_LEXER    pLexer;


     void (*mT__24)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__25)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__26)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__27)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__28)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__29)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__30)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__31)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__32)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__33)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__34)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__35)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__36)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__37)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__38)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__39)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__40)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__41)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mT__42)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mCOMMON_CHAR)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mHEX_CHAR)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mDIGIT)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mCRLF)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mHTAB)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mDQUOTE)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mLWS)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mPLUS)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mCOLON)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mSEMI)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mCOMMA)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mLAQUOT)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mRAQUOT)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mRPAREN)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mLPAREN)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mEQUAL)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mSLASH)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mSTAR)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mSP)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mOCTET)	(struct belle_sip_messageLexer_Ctx_struct * ctx);
     void (*mTokens)	(struct belle_sip_messageLexer_Ctx_struct * ctx);    const char * (*getGrammarFileName)();
    void	    (*free)   (struct belle_sip_messageLexer_Ctx_struct * ctx);
        
};

// Function protoypes for the constructor functions that external translation units
// such as delegators and delegates may wish to call.
//
ANTLR3_API pbelle_sip_messageLexer belle_sip_messageLexerNew         (pANTLR3_INPUT_STREAM instream);
ANTLR3_API pbelle_sip_messageLexer belle_sip_messageLexerNewSSD      (pANTLR3_INPUT_STREAM instream, pANTLR3_RECOGNIZER_SHARED_STATE state);

/** Symbolic definitions of all the tokens that the lexer will work with.
 * \{
 *
 * Antlr will define EOF, but we can't use that as it it is too common in
 * in C header files and that would be confusing. There is no way to filter this out at the moment
 * so we just undef it here for now. That isn't the value we get back from C recognizers
 * anyway. We are looking for ANTLR3_TOKEN_EOF.
 */
#ifdef	EOF
#undef	EOF
#endif
#ifdef	Tokens
#undef	Tokens
#endif 
#define T__42      42
#define LAQUOT      18
#define T__40      40
#define T__41      41
#define STAR      8
#define T__29      29
#define T__28      28
#define T__27      27
#define T__26      26
#define RAQUOT      19
#define T__25      25
#define HEX_CHAR      16
#define CRLF      4
#define T__24      24
#define HTAB      22
#define DQUOTE      7
#define EOF      -1
#define SEMI      9
#define LPAREN      20
#define COLON      13
#define T__30      30
#define T__31      31
#define RPAREN      21
#define T__32      32
#define T__33      33
#define SLASH      11
#define T__34      34
#define T__35      35
#define T__36      36
#define T__37      37
#define T__38      38
#define LWS      5
#define COMMA      10
#define T__39      39
#define COMMON_CHAR      17
#define SP      23
#define EQUAL      12
#define PLUS      15
#define DIGIT      6
#define OCTET      14
#ifdef	EOF
#undef	EOF
#define	EOF	ANTLR3_TOKEN_EOF
#endif

#ifndef TOKENSOURCE
#define TOKENSOURCE(lxr) lxr->pLexer->rec->state->tokSource
#endif

/* End of token definitions for belle_sip_messageLexer
 * =============================================================================
 */
/** \} */

#ifdef __cplusplus
}
#endif

#endif

/* END - Note:Keep extra line feed to satisfy UNIX systems */
