/*
SELETOR - SELETOR PARA PROGRAMAS NO MICRO
1993.11 José Quintas
*/

#include "inkey.ch"

PROCEDURE Main( mArqTxt )

   LOCAL mMenuOpcoes, acComandos := {}

   SetMode( 33, 100 )

   IF PCount() == 0
      mArqTxt := "seletor.cfg"
   ENDIF

   IF ! File( mArqTxt )
      CLS
      ?
      ? "Arquivo de configuracao nao encontrado!"
      ? "Crie com o nome SELETOR.CNF"
      ? "Se criar com outro nome, indique na linha de comando o nome escolhido"
      ? "Exemplo: _SELETOR OUTRO.CNF"
      cancel
   ENDIF

   mMenuOpcoes := MenuCria( mArqTxt, @acComandos )

   IF Len( mMenuOpcoes ) == 0
      Mensagem( "Nenhuma opcao encontrada!", " 13")
   ELSE
      TelaPrinc( "SELETOR" )
      MenuPrinc( mMenuOpcoes, acComandos )
      CLS
   ENDIF

   RETURN

STATIC FUNCTION MenuCria( mArqTxt, acComandos )

   LOCAL nCont, mTexto, mLinTexto, mNumPrg := 0, m_Pula, mPosi, mLinha
   LOCAL m_FileList, m_Tmp, m_Posicao, oElement

   MEMVAR  private_nMenuLevel, private_aMenuOpt
   PRIVATE private_nMenuLevel := 0, private_aMenuOpt := {}

   mTexto    := MemoRead( mArqTxt )
   mLinTexto := {}
   DO WHILE Len( mTexto ) > 0
      mPosi  := At( Chr( 13 ), mTexto + Chr( 13 ) ) - 1
      mLinha := SubStr( mTexto, 1, mPosi )
      mTexto := SubStr( mTexto, mPosi + 3 )
      mLinha := Trim( mLinha )
      IF Len( mLinha ) > 0 .AND. Left( mLinha, 1 ) != "*" // observacao
         AAdd( mLinTexto, mLinha )
      ENDIF
   ENDDO

   m_Pula = .F.
   FOR nCont = 1 TO Len( mLinTexto )
      IF Left( mLinTexto[ nCont ], 6 ) == "#endif"
         m_Pula = .F.
      ELSEIF m_Pula
      ELSEIF Left( mLinTexto[ nCont ], 2 ) == ">>"
         DO WHILE private_nMenuLevel > 0
            MenuUnDrop()
         ENDDO
         MenuOption( AllTrim( SubStr( mLinTexto[ nCont ], 3 ) ) )
         MenuDrop()
      ELSEIF Left( mLinTexto[ nCont ], 1 ) == ">"
         mNumPrg := mNumPrg + 1
         MenuOption( AllTrim( SubStr( mLinTexto[ nCont ], 2 ) ), StrZero( mNumPrg, 3 ) )
      ELSEIF Left( mLinTexto[ nCont ], 9 ) == "#ifexiste"
         m_FileList := {}
         m_Tmp := Upper( AllTrim( SubStr( mlinTexto[ nCont ], 11 ) ) )
         DO WHILE Len( m_Tmp ) > 0
            m_Posicao = At( " ", m_Tmp + " " ) - 1
            AAdd( m_FileList, SubStr( m_Tmp, 1, m_Posicao ) )
            m_Tmp = LTrim( SubStr( m_Tmp, m_Posicao + 1 ) )
         ENDDO
         m_Pula = .F.
         FOR EACH oElement IN m_FileList
            IF ! File( oElement )
               m_Pula = .T.
            ENDIF
         NEXT
      ELSE
         AAdd( acComandos, StrZero( mNumPrg, 3 ) + AllTrim( mLinTexto[ nCont ] ) )
      ENDIF
   NEXT
   DO WHILE private_nMenuLevel > 0
      MenuUnDrop()
   ENDDO

   RETURN private_aMenuOpt

FUNCTION MenuOption( mPrompt, mProg )

   LOCAL mNow, mCont

   MEMVAR private_aMenuOpt, private_nMenuLevel

   mNow := private_aMenuOpt
   FOR mCont = 1 TO private_nMenuLevel
      mNow := mNow[ Len( mNow ) ]
      IF ValType( mNow[ 2 ] ) # "A"
         mNow[ 2 ] := {}
      ENDIF
      mNow := mNow[ 2 ]
   NEXT
   AAdd( mNow, { mPrompt, {}, mProg } )

   RETURN NIL

FUNCTION MenuDrop()

   MEMVAR private_nMenuLevel

   private_nMenuLevel++

   RETURN NIL

FUNCTION MenuUnDrop()

   MEMVAR private_nMenuLevel

   private_nMenuLevel--

   RETURN NIL

FUNCTION TelaPrinc( mTitulo )

   SetColor( SetColorTitulo() )
   Scroll( 0, 0, 0, MaxCol(), 0 )
   @ 0, 0 SAY PadC( mTitulo, MaxCol() + 1 )
   SetColor( SetColorNormal() )
   Scroll( 1, 0, MaxRow() - 2, MaxCol(), 0 )
   SetColor( SetColorMensagem() )
   @ MaxRow() - 2, 0 TO MaxRow() - 2, MaxCol()
   Scroll( MaxRow() - 1, 0, MaxRow(), MaxCol(), 0 )

   RETURN NIL

FUNCTION MenuPrinc( mMenuOpt, acComandos )

   LOCAL mOpc := 1, mTecla, mCont, mLenTot, mDife, mEspEntre, mEspFora, mColIni
   LOCAL aMouseMenu, oElement

   FOR EACH oElement IN mMenuOpt
      oElement[ 1 ] := Str( oElement:__EnumIndex, 2 ) + ":" + oElement[ 1 ] + " "
   NEXT

   mLenTot := 0
   FOR EACH oElement IN mMenuOpt
      mLenTot += Len( oElement[ 1 ] )
   NEXT
   mDife     := Max( MaxCol() + 1 - mLenTot, 0 )
   mEspEntre := Int( mDife / ( Len( mMenuOpt ) + 1 ) )
   mEspFora  := Int( ( mDife - ( mEspEntre * ( Len( mMenuOpt ) + 1 ) ) ) / 2 )
   mColIni   := { mEspFora + mEspEntre }
   FOR mCont = 2 TO Len( mMenuOpt )
      AAdd( mColIni, mColIni[ mCont - 1 ] + Len( mMenuOpt[ mCont - 1, 1 ] ) + mEspEntre )
   NEXT

   Mensagem( "Selecione e tecle ENTER, ou codigo, ESC sai" )
   aMouseMenu := {}
   FOR EACH oElement IN mMenuOpt
      AAdd( aMouseMenu, { 2, mColIni[ oElement:__EnumIndex ], mColIni[ oElement:__EnumIndex ] - 1 + Len( oElement[ 1 ] ), 48 + oElement:__EnumIndex, 0 } )
   NEXT
   DO WHILE .T.
      FOR EACH oElement IN mMenuOpt
         SetColor( iif( oElement:__EnumIndex == mOpc, SetColorFocus(), SetColorNormal() ) )
         @ 2, mColIni[ oElement:__EnumIndex ] SAY oElement[ 1 ]
      NEXT
      SetColor( SetColorNormal() )
      Scroll( 4, 0, MaxRow() - 3, MaxCol(), 0 )
      SetColor( SetColorNormal() )
      BoxMenu( 4, mColIni[ mOpc ] - 20 + Int( Len( mMenuOpt[ mOpc, 1 ] ) / 2 ), mMenuOpt[ mOpc, 2 ], 1,, .T., .T., aMouseMenu, 1, acComandos )
      mTecla := Inkey( 0 )
      DO CASE
      CASE mTecla == 27 // ESC
         EXIT
      CASE mTecla == 4 // seta direita
         mOpc := iif( mOpc == Len( mMenuOpt ), 1, mOpc + 1 )
      CASE mTecla == 19 // seta esquerda
         mOpc := iif( mOpc == 1, Len( mMenuOpt ), mOpc - 1 )
      CASE mTecla > 48 .AND. mTecla < 49 + Len( mMenuOpt )// Numeros
         mOpc   := Abs( mTecla ) - 48
      ENDCASE
   ENDDO
   mensagem()

   RETURN NIL

FUNCTION BoxMenu( mLini, mColi, mMenuOpt, mOpc, mTitulo, mSaiSetas, mSaiFunc, aMouseConv, nLevel, acComandos )

   LOCAL mLinf, mColf, mTecla, aMouseLen, lExit, mNomeTela
   LOCAL nMRow, nMCol, XLin, xCol, m_ProgTxt, m_Prog, cTelaNoBox, cTelaOpcao, oElement

   mSaiSetas := iif( mSaiSetas == NIL, .F., mSaiSetas )
   mSaiFunc  := iif( mSaiFunc == NIL, .F., mSaiFunc )
   mTitulo   := iif( mTitulo == NIL, "", mTitulo )
   mOpc      := iif( mOpc == NIL, 1, mOpc )
   mLinf     := mLini + Len( mMenuOpt ) + iif( Empty( mTitulo ), 1, 2 )
   IF mLinf > MaxRow() - 4
      mLini := mLini + MaxRow() - 4 - mLinf
      mLinf := mLini + Len( mMenuOpt ) + iif( Empty( mTitulo ), 1, 2 )
   ENDIF
   mColi    := iif( mColi < 0, 0, mColi )
   mColf    := mColi + 37
   IF mColf > MaxCol() - 2
      mColi := mColi - 10 // Se nao conseguiu +5, tenta -5
      mColf := mColf - 10
      IF mColf > MaxCol() - 2
         mColi := mColi + MaxCol() - 2 - mColf
         mColf := mColi + 37
      ENDIF
   ENDIF
   SAVE SCREEN TO cTelaNoBox
   @ mLini, mColi TO mLinf, mColf
   IF ! Empty( mTitulo )
      @ mLini, mColi + 1 SAY Pad( mTitulo, mColf - mColi - 1 )
   ENDIF
   aMouseLen := Len( aMouseConv )
   ASize( aMouseConv, Len( aMouseConv ) + Len( mMenuOpt ) )
   FOR EACH oElement IN mMenuOpt
      AIns( aMouseConv, 1 )
      xLin := mLini + iif( Empty( mTitulo ), 0, 1 ) + oElement:__EnumIndex
      xCol := mColi + 1
      aMouseConv[ 1 ] := { xLin, xCol, xCol + 33, 64 + oElement:__EnumIndex, nLevel }
   NEXT
   DO WHILE .T.
      Mensagem( "Selecione e tecle ENTER, ou codigo, ESC sai" )
      FOR EACH oElement IN mMenuOpt
         SetColor( iif( oElement:__EnumIndex == mOpc, SetColorFocus(), SetColorMenu() ) )
         @ mLini + iif( Empty( mTitulo ), 0, 1 ) + oElement:__EnumIndex, mColi + 1 SAY " " + Chr( 64 + oElement:__EnumIndex ) + ":" + ;
            Pad( oElement[ 1 ], 31 ) + iif( Len( oElement[ 2 ] ) > 0, Chr( 175 ), " " ) + " "
      NEXT
      SetColor( SetColorNormal() )
      mTecla := Inkey( 0 )
      DO CASE
      CASE mTecla == 27 // .or. mTecla == K_MOUSERIGHT .or. mTecla == 0
         IF mTecla == 0
            CLS
            QUIT
         ENDIF
         IF nLevel == 1
            KEYBOARD Chr( 27 )
         ENDIF
         EXIT

      CASE .F. // mTecla == K_MOUSELEFT // Click Esquerda
         nMRow := MRow() // Rat_EqmRow()
         nMCol := MCol() // Rat_EqmCol()
         lExit := .F.
         FOR EACH oElement IN aMouseConv
            IF nMRow == oElement[ 1 ] .AND. nMCol >= oElement[ 2 ] .AND. nmCol <= oElement[ 3 ]
               IF oElement[ 5 ] == nLevel // Nivel Atual
                  KEYBOARD Chr( oElement[ 4 ] )
               ELSEIF oElement[ 5 ] == 0 // Principal
                  KEYBOARD Chr( oElement[ 4 ] )
                  lExit := .T.
               ELSE
                  KEYBOARD Replicate( Chr( 27 ), nLevel - oElement[ 5 ] - 1 ) + Chr( oElement[ 4 ] )
                  lExit := .T.
               ENDIF
               EXIT
            ENDIF
         NEXT
         IF lExit
            EXIT
         ENDIF
      CASE mTecla > 64 .AND. mTecla < 65 + Len( mMenuOpt ) // Letra menu atual
         mOpc := mTecla - 64
         KEYBOARD Chr( 13 )
      CASE mSaiSetas .AND. ( mTecla == 4 .OR. mTecla == 19 ) // setas
         IF nLevel == 1
            KEYBOARD Chr( mTecla )
         ENDIF
         EXIT
      CASE mTecla == 24
         mOpc := iif( mOpc == Len( mMenuOpt ), 1, mOpc + 1 )
      CASE mTecla == 5
         mOpc := iif( mOpc == 1, Len( mMenuOpt ), mOpc - 1 )
      CASE mTecla == 1
         mOpc := 1
      CASE mTecla == 6
         mOpc := Len( mMenuOpt )
      CASE mTecla == 13
         IF Len( mMenuOpt[ mOpc, 2 ] ) > 0
            BoxMenu( mLini + iif( Empty( mTitulo ), 0, 1 ) + mOpc, mColi + 5, ;
               mMenuOpt[ mOpc, 2 ], 1, mMenuOpt[ mOpc, 1 ], .T., .T., aMouseConv, nLevel + 1, acComandos )
         ELSEIF ValType( mMenuOpt[ mOpc, 3 ] ) == "C"
            // esta variavel controla o tratamento de codigos de item
            Mensagem()
            SAVE SCREEN TO cTelaOpcao
            m_Prog := mMenuOpt[ mOpc, 3 ] // atualiza variavel do sistema
            IF "(" $ m_Prog
               m_ProgTxt := StrTran( m_Prog, "(", "_" )
               m_ProgTxt := StrTran( m_ProgTxt, ")", "" )
            ELSE
               m_ProgTxt := m_Prog
            ENDIF
            SetColor( SetColorTitulo() )
            mNomeTela := "(" + m_ProgTxt + ") " + Upper( mMenuOpt[ mOpc, 1 ] )
            @ 0, 0 SAY PadC( mNomeTela, MaxCol() + 1 )
            SetColor( SetColorNormal() )
            Scroll( 1, 0, MaxRow() - 3, MaxCol(), 0 )
            IF "(" $ mMenuOpt[ mOpc, 3 ]
               &( mMenuOpt[ mOpc, 3 ] )
            ELSE
               RodaBat( mMenuOpt[ mOpc, 3 ], acComandos )
            ENDIF
            RESTORE SCREEN FROM cTelaOpcao
            CLOSE DATABASES
         ELSEIF ValType( mMenuOpt[ mOpc, 3 ] ) == "B"
            Mensagem()
            SAVE SCREEN TO cTelaOpcao
            Scroll( 2, 0, MaxRow() - 3, MaxCol(), 0 )
            Eval( mMenuOpt[ mOpc, 3 ] )
            RESTORE SCREEN FROM cTelaOpcao
         ENDIF
      CASE SetKey( mTecla ) != NIL
         Eval( SetKey( mTecla ), ProcName(), ProcLine(), ReadVar() )
      OTHERWISE // Vamos ver se e' atalho
         mTecla := Asc( Upper( Chr( mTecla ) ) )
         lExit  := .F.
         FOR EACH oElement IN aMouseConv
            IF mTecla == oElement[ 4 ]
               IF oElement[ 5 ] == nLevel // Nivel Atual
                  KEYBOARD Chr( oElement[ 4 ] )
               ELSEIF oElement[ 5 ] == 0 // Principal
                  KEYBOARD Chr( oElement[ 4 ] )
                  lExit := .T.
               ELSE
                  KEYBOARD Replicate( Chr( K_ESC ), nLevel - oElement[ 5 ] - 1 ) + Chr( oElement[ 4 ] )
                  lExit := .T.
               ENDIF
               EXIT
            ENDIF
         NEXT
         IF lExit
            EXIT
         ENDIF
      ENDCASE
   ENDDO
   FOR EACH oElement IN mMenuOpt
      ADel( aMouseConv, 1 )
   NEXT
   ASize( aMouseConv, aMouseLen )
   RESTORE SCREEN FROM cTelaNoBox

   RETURN NIL

FUNCTION RodaBat( mNumPrg, acComandos )

   LOCAL cTxt := "", oElement, cFileName := "tmp.bat"

   FOR EACH oElement IN acComandos
      IF Left( oElement, 3 ) == mNumPrg
         cTxt += SubStr( oElement, 4 ) + hb_Eol()
      ENDIF
   NEXT
   hb_MemoWrit( cFileName, cTxt )
   RUN ( cFileName )
   ? "Tecle algo para retornar ao JPA-SELETOR"
   Inkey(0)
   FErase( cFileName )
   RESTORE SCREEN

   RETURN NIL

FUNCTION SetColorNormal()    ; RETURN "W/B"
FUNCTION SetColorTitulo()    ; RETURN "N/W"
FUNCTION SetColorMensagem()  ; RETURN "W/N"
FUNCTION SetColorFocus()     ; RETURN "N/GR"
FUNCTION SetColorMenu()      ; RETURN "W/B"

FUNCTION Mensagem( cTexto, lPausa )

   LOCAL nKey := 0, cSetColor := SetColor()

   SetColor( SetColorMensagem() )
   @ MaxRow() - 1, 0 CLEAR TO MaxRow(), MaxCol()
   IF cTexto == NIL
      RETURN NIL
   ENDIF
   @ MaxRow() - 1, 0 SAY cTexto
   SetColor( cSetColor )
   IF lPausa != NIL
      DO WHILE nKey != K_ENTER
         nKey := Inkey()
      ENDDO
   ENDIF

   RETURN NIL
