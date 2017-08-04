/*
J - Compilacao com Clipper 5.x
1991,11 - José Quintas

   Proj_Compiler C=Clipper H=Harbour
   c.bat
   thisprogram.exe
   call c:\temp\makefile.bat
*/

#define F_NAME    1
#define F_SIZE    2
#define F_DATE    3
#define F_TIME    4
#define F_ATTRIB  5
#define F_VALUE   6

MEMVAR Proj_Compiler, Proj_WithDebug, Proj_FileMake, Proj_TmpDir, Proj_FileCfg, Proj_ExeName
MEMVAR aPrgFileList, aLnkFileList, aExeFileList, mTmpListac, mSourcec

PROCEDURE Main( ... )

   LOCAL aCmdParam , nCont, nCont2, lActionLink, mNome, lActionCompile, mObj, lActionLinkThis, oElement
   LOCAL mFilc, mFilHb, mFilCCont, mInkey

   aCmdParam := { ... }

   Apresenta()

   Proj_Compiler  := ""
   Proj_WithDebug := .F.
   FOR EACH oElement IN aCmdParam
      DO CASE
      CASE Upper( oElement ) $ "H,C"
         Proj_Compiler = Upper( oElement )
         ? "Compilador " + Proj_Compiler
      CASE oElement == "-b" .OR. oElement == "b"
         Proj_WithDebug := .T.
         ? "Debug Ativado"
      ENDCASE
   NEXT
   Proj_Compiler := iif( Empty( Proj_Compiler ), "C", Proj_Compiler )

   ? "Compilador " + Proj_Compiler
   ? "Debug " + iif( Proj_WithDebug, "Ativado", "Desativado" )

   // OL_AutoYield(.t.)

   Proj_TmpDir   := "c:\temp\"
   Proj_FileMake := Proj_TmpDir + "makefile.bat"
   Proj_FileCfg  := hb_DirBase() + "J50.CFG"

   CheckNewFolder()

   SET EXACT ON

   lActionLink := .F.

   FErase( Proj_FileMake )
   aPrgFileList := {}
   aLnkFileList := {}
   aExeFileList := {}

   aPrgFileList := Directory( "*.prg" )
   IF Len( aPrgFileList ) == 0
      Beep()
      ? "No PRG Files Found"
      RETURN
   ENDIF

   // checks .PRG for invalid date
   FOR EACH oElement IN aPrgFileList
      oElement[ F_NAME ] := hb_FNameName( oElement[ F_NAME ] )
      IF DToS( oElement[ F_DATE ] ) + oElement[ F_TIME ] > DToS( Date() ) + Time()
         ? oElement[ F_NAME ] + ".PRG With Date Greater Than Now"
      ENDIF
   NEXT

   // checks .LNK

   aLnkFileList := Directory( "*.lnk" )
   FOR EACH oElement IN aLnkFileList
      oElement[ F_NAME ] := hb_FNameName( oElement[ F_NAME ] )
      oElement[ F_ATTRIB ] := .F.
      AAdd( oElement, Lower( MemoRead( oElement[ F_NAME ] + ".lnk" ) ) )
   NEXT

   IF Len( aLnkFileList ) == 0
      CriaLnk()
   ENDIF

   // OBJ X PRG

   FOR EACH oElement IN aPrgFileList
      mObj := Directory( Proj_TmpDir + oElement[ F_NAME ] + ".obj" )
      lActionCompile := ( Len( mObj ) == 0 )
      DO CASE
      CASE lActionCompile
         ? oElement[ F_NAME ] + ".OBJ not found, will be created"
      CASE DToS( mObj[ 1, F_DATE ] ) + mObj[ 1, F_TIME ] < DToS( oElement[ F_DATE ] ) + oElement[ F_TIME ]
         ? oElement[ F_NAME ] + ".OBJ will be updated"
         lActionCompile := .T.
      ENDCASE
      oElement[ F_ATTRIB ] := lActionCompile
      IF lActionCompile
         lActionLink := .T.
      ENDIF
   NEXT

   // LNK: DLL or EXE and PRG List

   FOR EACH oElement IN aLnkFileList
      IF "output" $ oElement[ F_VALUE ]
         mNome := oElement[ F_VALUE ]
         mNome := SubStr( mNome, At( "output", mNome ) + 7 )
         IF At( Chr( 13 ), mNome ) != 0
            mNome := SubStr( mNome, 1, At( Chr( 13 ), mNome ) -1 )
         ENDIF
      ELSE
         mNome := aPrgFileList[ 1, F_NAME ]
      ENDIF
      IF "exetype" $ Lower( oElement[ F_VALUE ] ) // Se DLL
         Proj_ExeName := oElement[ F_NAME ] + ".dll" // Mesmo nome do LNK
      ELSE
         Proj_ExeName := mNome + ".exe"
      ENDIF
      lActionLinkThis := .F.
      FOR nCont2 = 1 TO Len( aPrgFileList )
         IF "file " + aPrgFileList[ nCont2, 1 ] + Chr( 13 ) $ oElement[ F_VALUE ] .OR. aPrgFileList[ nCont2, 1 ] + ".obj" $ oElement[ F_VALUE ] // xharbour
            IF aPrgFileList[ nCont2, 5 ]
               lActionLinkThis := .T.
               EXIT
            ENDIF
         ENDIF
      NEXT
      aExeFileList := Directory( Proj_ExeName )
      IF Len( aExeFileList ) == 0
         lActionLinkThis := .T.
      ELSE
         IF DToS( oElement[ F_DATE] ) + oElement[ F_TIME ] > DToS( aExeFileList[ 1, F_DATE ] ) + aExeFileList[ 1, F_TIME ]
            lActionLinkThis := .T.
         ENDIF
      ENDIF
      IF lActionLinkThis
         oElement[ F_ATTRIB ] := .T.
         lActionLink := .T.
         ? Proj_ExeName + " Will Be Created"
      ENDIF
   NEXT

   SET ALTERNATE to ( Proj_FileMake )

   // Create list of PRGs to Compile

   mFilC := { "" }
   mFilHb := { "" }
   mFilcCont := 1
   FOR EACH oElement IN aPrgFileList
      IF oElement[ F_ATTRIB ]
         IF Proj_Compiler == "H"
            IF mFilcCont > 10
               mFilcCont := 1
               AAdd( mFilC, "" )
               AAdd( mFilHb, "" )
            ENDIF
            mFilC[ Len( mFilC ) ] += ( " " + Proj_TmpDir + oElement[ F_NAME ] + ".c" )
            mFilHb[ Len( mFilC ) ] += ( " " + oElement[ F_NAME ] + ".prg" )
            mFilcCont += 1
         ELSE
            WriteTxt( "if not errorlevel 1 clipper " + oElement[ F_NAME ] + " -m " + iif( Proj_WithDebug, "-b", "" ) + " -o" + Proj_TmpDir )
         ENDIF
      ENDIF
   NEXT

   // Create compile commans

   IF Proj_Compiler == "H"
      FOR nCont = 1 TO Len( mFilC )
         IF Len( Trim( mFilC[ nCont ] ) ) # 0
            // Retirado -z, pra ficar igual clipper
            WriteTxt( "if not errorlevel 1 \harbour\bin\harbour " + mFilHb[ nCont ] + " -n -m " + iif( Proj_WithDebug, "-b", "" ) + " -o" + Proj_TmpDir + " %2 %3" )
            // WriteTxt("if not errorlevel 1 \tools\bcc55\bin\bcc32 -c -q -d -6 -O2 -OS -Ov -Oi -Oc -tW -DUNICODE -tWM -Q -w-sig- -n"+Proj_TmpDir+" -Id:\tools\bcc55\include -Id:\harbour\include; "+mFilC[nCont])
            WriteTxt( "if not errorlevel 1 cl.exe -nologo -c -O2 -W4 -wd4127 -DUNICODE -Id:\harbour\include -Foc:\temp\ " + mFilC[ nCont ] )
            mTmpListaC := AllTrim( mFilC[ nCont ] )
            DO WHILE Len( mTmpListaC ) > 0
               mSourceC   := AllTrim( SubStr( mTmpListaC, 1, At( " ", mTmpListaC + " " ) ) )
               mTmpListaC := AllTrim( SubStr( mTmpListaC, At( " ", mTmpListaC + " " ) ) )
               WriteTxt( "del " + mSourceC ) // Apaga arquivo .c
            ENDDO
         ENDIF
      NEXT
      // WriteTxt("if not errorlevel 1 \tools\bcc55\bin\brcc32 -Id:\tools\bcc55\include -id:\harbour\include resource\jpa.rc -foc:\temp\jpa.res")
      // WriteTxt("if exists jpa.prg rc.exe -nologo -Ic:\harbour\include -fo c:\temp\jpa.res resource\jpa.rc")
   ENDIF

   // If don't need to link, ask to user

   IF ! lActionLink
      Beep()
      ? "Nothing to Link"
      ? "Link Anywhere (Y/N)?"
      mInkey := 0
      DO WHILE ! Upper( Chr( mInkey ) ) $ "YN"
         mInkey := Inkey( 0 )
      ENDDO
      IF Upper( Chr( mInkey ) ) == "Y"
         FOR EACH oElement IN aLnkFileList
            oElement[ F_ATTRIB ] := .T.
         NEXT
         lActionLink := .T.
      ENDIF
   ENDIF

   // Create link commands

   FOR EACH oElement IN aLnkFileList
      IF oElement[ F_ATTRIB ]
         IF Proj_Compiler == "H"
            WriteTxt( "if not errorlevel 1 \tools\bcc55\bin\ilink32 @" + oElement[ F_NAME ] + ".lnk" )
         ELSE
            WriteTxt( "if not errorlevel 1 blinker @" + oElement[ F_NAME ] + ".lnk" )
         ENDIF
      ENDIF
   NEXT

   // Compress with UPX for Harbour/xHarbour

   IF Proj_Compiler == "H" .AND. lActionLink
      WriteTxt( "if not errorlevel 1 \harbour\bin\upx " + Proj_ExeName )
      WriteTxt( "for %%a in (*.tds) do del %%a" )
   ENDIF

   // Will show when compilation began

   WriteTxt( "Echo Inicio da Compilacao " + Time() )
   SET ALTERNATE TO
   fDelEof( Proj_FileMake )
   ?
   SetColor( "GR+/N" )
   ? Replicate( Chr( 196 ), MaxCol() -1 )
   SetColor( "W/N" )
   ?

   RETURN

FUNCTION Beep()

   Tone( 164.80, 6 )

   RETURN NIL

FUNCTION Apresenta()

   CLS
   SetColor( "GR+/N" )
   ? Replicate( Chr( 196 ), MaxCol() -1 )
   SetColor( "W+/B" )
   ? Space( MaxCol() -1 )
   ? PadL( "DELPO Clipper Incremental Compile", MaxCol() -1 )
   ? PadL( "Checks Dll, Exe, Lnk, Prg, Obj", MaxCol() -1 )
   ? PadL( "(c) Jose M. C. Quintas", MaxCol() -1 )
   ? Space( MaxCol() -1 )
   SetColor( "GR+/N" )
   ? Replicate( Chr( 196 ), MaxCol() -1 )
   SetColor( "W/N" )
   ?

   RETURN NIL

FUNCTION WriteTxt( mTexto )

   mTexto := iif( mTexto == NIL, "", mTexto )
   SET ALTERNATE ON
   SET CONSOLE OFF
   ?? mTexto
   ?
   SET ALTERNATE OFF
   SET CONSOLE ON

   RETURN NIL

FUNCTION CriaLnk()

   // Main/First .PRG will be first sorted by name, or small name

   LOCAL nCont, nCont2, mLstAlfa, mNomeExe, mNomeAtu, mTroca, mTemp1, mTemp2

   mNomeExe  := aPrgFileList[ 1, 1 ]
   FOR nCont = 1 TO Len( aPrgFileList )
      mNomeAtu := aPrgFileList[ nCont, 1 ]
      mTroca   := .F.
      DO CASE
      CASE Len( mNomeAtu ) < Len( mNomeExe )
         mTroca := .T.
      CASE Pad( mNomeAtu, 10 ) < Pad( mNomeExe, 10 ) .AND. Len( mNomeAtu ) < Len( mNomeExe )
         mTroca := .T.
      ENDCASE
      IF mTroca
         mTemp1 := aPrgFileList[ 1 ]
         aPrgFileList[ 1 ] := aPrgFileList[ nCont ]
         FOR nCont2 = 2 TO nCont
            mTemp2 := aPrgFileList[ nCont2 ]
            aPrgFileList[ nCont2 ] := mTemp1
            mTemp1 := mTemp2
         NEXT
         mNomeExe := mNomeAtu
      ENDIF
   NEXT

   // Create LNK File

   SET ALTERNATE TO ( Proj_TmpDir + aPrgFileList[ 1, 1 ] + ".lnk" )
   SET ALTERNATE ON
   SET CONSOLE OFF
   IF Proj_Compiler == "C"
      ? "blinker clipper symbol off" // 20/06
      ? "blinker executable clipper F250"
      ? "blinker environment override"
      ? "blinker environment clipper jpa"
      ? "blinker executable extended"
      ? "blinker executable compress"
      ? "blinker incremental off"
      ? "blinker procedure depth 120"
      ? "blinker executable alignment 128"
      ? "blinker extmem limit 8000"
      ? "blinker lowmem reserve 32"
      ? "blinker message wink"
   ENDIF

   IF Proj_Compiler == "H"
      ?? "-Gn -Tpe -v -aa c0w32.obj -Ld:\tools\bcc55\lib;d:\tools\bcc55\lib\PSDK;d:\harbour\lib\win\bcc;d:\harbour\bin +" // GUI
      ? "c0w32.obj +"
      FOR nCont = 1 TO Len( aPrgFileList )
         ? Lower( Proj_TmpDir + aPrgFileList[ nCont, 1 ] ) + ".obj +"
      NEXT
      ? " , +"
      // Importante: a ordem e/ou LIBs faz diferenca conforme o que estiver usando
      ? aPrgFileList[ 1, 1 ] + ".exe,NUL, +"
      ? "d:\harbour\lib\3rd\win\bcc\unicows.lib +" // Para funcionar tambem no W98
      ? "hbtip.lib +"
      ? "hbct.lib +"
      ? "hbwin.lib +"
      ? "hbziparc.lib +"
      ? "minizip.lib +"
      ? "hbmzip.lib +"
      ? "hbextern.lib +"
      ? "hbdebug.lib +"
      ? "hbvmmt.lib +"
      ? "hbrtl.lib +"
      ? "hblang.lib +"
      ? "hbcpage.lib +"
      ? "gtwvt.lib +"
      ? "gtcgi.lib +"
      ? "gtpca.lib +"
      ? "gtstd.lib +"
      ? "gtwin.lib +"
      ? "gtgui.lib +"
      ? "hbrdd.lib +"
      ? "hbuddall.lib +"
      ? "hbusrrdd.lib +"
      ? "rddntx.lib +"
      ? "rddcdx.lib +"
      ? "rddnsx.lib +"
      ? "rddfpt.lib +"
      ? "hbrdd.lib +"
      ? "hbhsx.lib +"
      ? "hbsix.lib +"
      ? "hbmacro.lib +"
      ? "hbcplr.lib +"
      ? "hbcommon.lib +"
      ? "kernel32.lib +"
      ? "user32.lib +"
      ? "gdi32.lib +"
      ? "advapi32.lib +"
      ? "ws2_32.lib +"
      ? "winspool.lib +"
      ? "comctl32.lib +"
      ? "comdlg32.lib +"
      ? "shell32.lib +"
      ? "uuid.lib +"
      ? "ole32.lib +"
      ? "oleaut32.lib +"
      ? "mpr.lib +"
      ? "winmm.lib +"
      ? "mapi32.lib +"
      ? "imm32.lib +"
      ? "msimg32.lib +"
      ? "wininet.lib +"
      ? "hbpcre.lib +"
      ? "hbzlib.lib +"
      ? "cw32mt.lib +"
      ? "import32.lib +"
      ? ",, d:\cdrom\fontes\integra\resource\jpa.res +"
      ?
      ? ";"
   ELSE
      ? "output " + aPrgFileList[ 1, 1 ]
      mLstAlfa := {}
      FOR nCont = 2 TO Len( aPrgFileList )
         AAdd( mLstAlfa, Lower( aPrgFileList[ nCont, 1 ] ) )
      NEXT
      IF Len( mLstAlfa ) > 0
         ASort( mLstAlfa )
         ASize( mLstAlfa, Len( mLstAlfa ) + 1 )
         AIns( mLstAlfa, 1 )
      ELSE
         AAdd( mLstAlfa, "" )
      ENDIF
      mLstAlfa[ 1 ] := Lower( aPrgFileList[ 1, 1 ] )
      FOR nCont = 1 TO Len( mLstAlfa )
         ? "file " + mLstAlfa[ nCont ]
      NEXT
      ? "file \cdrom\fontes\lib\apporign" // Maligno AppPath
      ? "file \cdrom\fontes\lib\volsernr" // Maligno Vol.Serial
      ? "file \cdrom\fontes\lib\crc32clc" // Maligno CRC32
      ? "lib \cdrom\fontes\lib\OsLib"
      ? "lib Super"
      IF Proj_Compiler == "C"
         // ? "file blxclp52" // no caso de rodar DLL
         ? "search blxclp52"
         ? "search six3"
         ? "file \cdrom\fontes\lib\sixuk"
         // ? "file \cdrom\fontes\lib\sixcdx" // usa somente sixcdx
      ENDIF
   ENDIF
   SET CONSOLE ON
   SET ALTERNATE OFF
   SET ALTERNATE TO
   fDelEof( Proj_TmpDir + aPrgFileList[ 1, 1 ] + ".lnk" )

   AAdd( aLnkFileList, ;
      { Proj_TmpDir + aPrgFileList[ 1, 1 ], 0, CToD( "" ), Time(), .F., MemoRead( Proj_TmpDir + aPrgFileList[ 1, 1 ] + ".lnk" ) } )

   RETURN NIL

// CFG File, with last compilation folder

STATIC FUNCTION CheckNewFolder()

   LOCAL mOldFolder, mNewFolder, mAnswer, mText, mDirectory, nCont, mOldCompiler

   IF File( Proj_FileCfg )
      mText        := MemoRead( Proj_FileCfg )
      mOldFolder   := XmlNode( mText, "lastdir" )
      mOldCompiler := XmlNode( mText, "compiler" )
   ELSE
      mOldFolder := "NOTHING"
   ENDIF
   mNewFolder := Upper( hb_cwd() ) // Harbour Upper
   IF ! ( mOldFolder == mNewFolder .AND. Proj_Compiler == mOldCompiler ) // Nao serve !=, senao falha
      ?
      @ Row(), Col() SAY "Last Directory:" + mOldFolder
      ? "Current Directory:" + mNewFolder
      ?
      @ Row(), Col() SAY "Directory or Compiler Changed!!! Erase OBJ in " + Proj_TmpDir + " (S/N)?" COLOR "W/R"
      ?
      Beep()
      mAnswer := " "
      DO WHILE ! mAnswer $ "YNS" + Chr( 27 )
         mAnswer := Upper( Chr( Inkey( 0 ) ) )
         IF LastKey() == 27 .OR. mAnswer $ "SYN"
            EXIT
         ENDIF
      ENDDO
      IF LastKey() == 27
         FErase( Proj_FileMake )
         QUIT
      ENDIF
      IF mAnswer $ "YS"
         mDirectory := Directory( Proj_TmpDir + "*.obj" )
         FOR nCont = 1 TO Len( mDirectory )
            ? "Erasing " + Proj_TmpDir + mDirectory[ nCont, 1 ]
            FErase( Proj_TmpDir + mDirectory[ nCont, 1 ] )
         NEXT
         Inkey( 2 )
      ENDIF
   ENDIF
   FErase( Proj_FileCfg )
   MemoWrit( Proj_FileCfg, XmlTag( "lastdir", mNewFolder ) + XmlTag( "compiler", Proj_Compiler ) )

   RETURN NIL

STATIC FUNCTION XmlNode( cText, cTag )

   LOCAL cValue := "", cTagStart, cTagEnd

   cTagStart := "<" + cTag + ">"
   cTagEnd   := "</" + cTag + ">"

   IF At( cTagStart, cText ) != 0 .AND. At( cTagEnd, cText ) != 0
      cValue := SubStr( cText, At( cTagStart, cText ) + Len( cTagStart ) )
      cValue := SubStr( cValue, 1, At( cTagEnd, cValue ) -1 )
   ENDIF

   RETURN cValue

STATIC FUNCTION XmlTag( cTag, cValue )

   LOCAL cText

   cText := "<" + cTag + ">" + cValue + "</" + cTag + ">"

   RETURN cText

FUNCTION FDelEof( mFile )

   LOCAL nHandle

   nHandle = FOpen( mFile, 2 )
   FSeek( nHandle, -1, 2 )
   FWrite( nHandle, "" )
   FClose( nHandle )

   RETURN NIL
