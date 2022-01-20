:Namespace findrefs ⍝ V1.24
⍝ Find References and Reference Loops
⍝ 2015 05 21 Adam: NS header
⍝ 2015 12 30 Adam: Added Test
⍝ 2016 03 10 DanB: added ghost reference search and modified aliases output
⍝ 2016 03 25 DanB: removed -root and added [=] to -aliases
⍝ 2016 04 19 DanB: bug fix for ⎕ORs
⍝ 2018 05 08 Adam: help overhaul
⍝ 2019 02 04 Adam: help 
⍝ 2021 12 11 MKrom: Do not try to follow DMX'es (ODF has rank 2)
⍝ 2021 12 14 MKrom: Implement -xws switch

    ⎕IO←⎕ML←1 ⋄ CR←⎕ucs 13  ⋄  If←/⍨

    ∇ r←List
      r←⎕NS ⍬
    ⍝ Name, group, short description and parsing rules
      r.(Name Group)←'FindRefs' 'WS'
      r.Desc←'Follow references in the workspace until all references have been found'
      r.Parse←'-loops  -aliases[=]  -nolist -xws'
    ∇

    ∇ r←level Help Cmd;c2;c3
      r←'Follow references in the workspace until all references have been found',CR
      r,←'    ]',Cmd,' [<ns>] [-aliases[=<n>]] [-nolist]',CR
      (c2 c3)←(CR,']',Cmd)∘,¨' -??  ⍝ for more information' ' -??? ⍝ for examples'
      :If level=0
          r,←c2,c3
      :ElseIf level=1
          r,←'<ns>            initial namespace (default is #)',CR
          r,←CR,'-aliases[=<n>]  only list up to <n> aliases (default is all) for each ref found'
          r,←CR,'-loops          report reference loops'
          r,←CR,'-nolist         do not list namespaces (useful with -loops)'
          r,←CR,c3
      :ElseIf level>1
          r,←'Examples:',CR
          r,←CR,'        )CLEAR'
          r,←CR,'    clear ws'
          r,←CR,'        A←⎕NS '''' ⋄ B←C←D←A'
          r,←CR,'        V←0 C 2 99'
          r,←CR,'        ]',Cmd
          r,←CR,'    #: followed 6 pointers to reach a total of 2 "refs"'
          r,←CR,'      Name'
          r,←CR,'      #'
          r,←CR,'      #.B+4 more'
          r,←CR,''
          r,←CR,'        ]',Cmd,' -alias'
          r,←CR,'    #: followed 6 pointers to reach a total of 2 "refs"'
          r,←CR,'      Name  Alias 1  Alias 2  Alias 3  Alias 4'
          r,←CR,'      #'
          r,←CR,'      #.B   #.C      #.D      #.V[2]   #.A (DF=#.[Namespace])'
          r,←CR,''
          r,←CR,'        ]',Cmd,' -alias=3'
          r,←CR,'    #: followed 6 pointers to reach a total of 2 "refs"'
          r,←CR,'      Name  Alias 1  Alias 2  Alias 3'
          r,←CR,'      #'
          r,←CR,'      #.B   #.C      #.D      #.V[2]+1 more'
          r,←CR,''
          r,←CR,'      ''X'' ⎕NS '''''
          r,←CR,'      A.t←X'
          r,←CR,'      X.z←A'
          r,←CR,'        ]',Cmd,' -loop'
          r,←CR,'    #: followed 31 pointers to reach a total of 3 "refs"'
          r,←CR,'      Name'
          r,←CR,'      #'
          r,←CR,'      #.B+11 more'
          r,←CR,'      #.X+11 more'
          r,←CR,'     1 loop found:'
          r,←CR,'     Loop #1: #.B   → #.X'
          r,←CR,'       #.X = #.B.t'
          r,←CR,'       #.B = #.X.z'
          r,←CR,''
          r,←CR,'        )CLEAR'
          r,←CR,'    clear ws'
          r,←CR,'        ⎕FIX '':class B'' '':endclass'''
          r,←CR,'        ⎕FIX '':class A:B'' '':endclass'''
          r,←CR,'        ⎕EX ''B'''
          r,←CR,'        ]',Cmd,' A'
          r,←CR,'     #.A: followed 1 pointers to reach a total of 1 "refs"'
          r,←CR,'      Name'
          r,←CR,'      #.A'
          r,←CR,'     #.A''s base class is missing: #.B'
          r,←CR,CR,']',Cmd,' -?? ⍝ for syntax information'
      :EndIf
    ∇

    ∇ r←Run(Cmd Line);loop;i;j;from;to;REFS;NAMES;LOOPS;root;z;COUNT;NOTES;n;more;FINDXWS;NA;XWS
      root←# ⍝ find where to start from
      root←##.THIS⍎r←1⊃Line.Arguments,'#'
      (r,' is an invalid space')⎕SIGNAL 11 If 9≠⎕NC'root'
      NA←1+(1+2⌊n)⊃0(9999*n≡1),n←0 Line.Switch'aliases' ⍝ base name + aliases
      FINDXWS←Line.xws
      n←((~'#'∊r)/'.',⍨⍕##.THIS),r
      (REFS NAMES LOOPS COUNT NOTES XWS)←n FINDLOOPS root
     
      r←((⍕root),': followed ',(⍕COUNT),' pointers to reach a total of ',(⍕⍴REFS),' "refs"')''
     
      :If Line.nolist<NAMES≢,⊂,⊂,'#'  ⍝ skip empty #
         ⍝ Display each name found and other references (aliases) to it if so desired.
         ⍝ We display a list of max 5 names by default but the user may want to see another number.
         ⍝ The rule is:
         ⍝ - if the user does NOT want to see them all we only show one column
         ⍝ - if s/he wants them we show 5 or as specified by -alias=
         ⍝ in any case the last the column will show "+more" if the number of aliases does not fit in
     
          :If NA=0 ⋄ r,←(⊂'Name'),1↑¨NAMES
          :Else
              z←{(' '∨.≠⍵)/⍵}¨↑NAMES
              :If ∨/more←0<n←NA-⍨≢¨NAMES
                  z←z[;⍳NA]
                  (more/z[;NA]),←more/'+',¨(⍕¨n),¨⊂' more'
              :EndIf
              z←((⊂'Name'),'Alias '∘,¨⍕¨⍳¯1+⊢/⍴z)⍪z
              r,←↓⍕z
          :EndIf
          r,←NOTES
      :EndIf
     
      :If Line.loops
          r,←((⍕i),' loop',(i=1)↓'s found:'↓⍨-0=i←⍴LOOPS)''
     
          :For i :In ⍳⍴LOOPS
              r,←⊂'Loop #',(⍕i),': ',4↓⍕' → '∘,¨(⍕∘⊃¨loop←NAMES[REFS⍳i⊃LOOPS])~¨' '
              :For j :In 1⌽⍳⍴loop
                  from←((1+(⍴loop)|j-2),1)⊃loop
                  to←j⊃loop
                  from←1⊃(((1∊¨from∘⍷¨to)/to)~⊂from),⊂'???'
                  r,←⊂'   ',(1⊃to),' = ',from
              :EndFor
              r,←⊂''
          :EndFor
      :EndIf
      
      :If 0≠≢XWS
          ⎕←⍪'Cross-workspace refs:' '',XWS
      :EndIf

      r←⍕⍪r
    ∇

    ODF←{(⍵.⎕DF v)⊢ ⍕⍵ ⊣v←⍵.⎕DF ⎕NULL} ⍝ Original Display Form

    ⍝ Ghost references
    ⍝ These are some types of references that are no longer directly referenced:
    ⍝ - class A is based on B and B is erased
    ⍝ - class A is based on B in a ws on file and only A is )COPYed
    ⍝ - A.B is a ref stored in X and A is erased. B is the ref kept in X and its parent (X.##) points to now defunct A

    ∇ (FOUND NAMES PATHS COUNT NOTES XWS)←name FINDLOOPS ref;STACK;FINDPATH;XWS
    ⍝ Find loops starting at ref
      COUNT←0
      FINDPATH←0 ⍝ 1 for FINDPATH mode
      STACK←⍬
      FOUND←⍬ ⍝ List of refs that have been found
      NAMES←⍬ ⍝ Names of FOUND refs
      PATHS←⍬ ⍝ List of refs that are known to be part of a loop
      XWS  ←⍬
      NOTES←⊂''
     
      name findrefsof (rootws ref) ref
      PATHS←∪PATHS
      NAMES←{⍵[⍋(999×'('∊¨⍵)⌈⊃∘⍴¨⍵]}¨NAMES ⍝ Shortest names first
     ⍝ Remove the Display Form if it matches the 1st name
      NAMES←{(~∨\¨(⊂1⌽') (DF=',1⊃⍵)⍷¨⍵)/¨⍵}¨NAMES
      :If 0≠⍴PATHS
          PATHS←({(⍳⍴⍵)=⍵⍳⍵}{⍵[⍋↑⍵]}¨⍕¨¨{NAMES[FOUND⍳⍵]}¨PATHS)/PATHS ⍝ De-duplicate on names
      :EndIf
    ∇

    ∇ PATHS←{start}FINDPATHS ref;STACK;FINDPATH;FOUND;NAMES;TARGET;XWS
     ⍝ Find paths to ref
     ⍝ /// no longer used?
     
      :If 0=⎕NC'start' ⋄ start←# ⋄ :EndIf
      FINDPATH←1 ⋄ TARGET←ref ⍝ 1 for FINDPATH mode
      STACK←⍬
      FOUND←⍬ ⍝ List of refs that have been found  
      NAMES←⍬ ⍝ Names of FOUND refs
      PATHS←⍬ ⍝ List of refs that are known to be part of a loop
     
      (⍕start)findrefsof start
    ∇

    ∇ name findnestedrefs (oldroot v);i;m;refs
     ⍝ Find refs within an array
      :If (v≢⎕NULL)>isOR v
          :Trap 16 ⋄ v←⊃⍣(0∊⍴v)⊢v ⋄ :Else ⋄ →0 ⋄ :EndTrap
     
          :For i :In refs/⍳⍴refs←,{9∊⎕NC'⍵'}¨v ⍝ Ref elements
              (name fmtidx i,⍴v)findrefsof oldroot (i⊃,v)
          :EndFor
          :For i :In m/⍳⍴m←(~refs)∧,326=⎕DR¨v ⍝ Nested pointer arrays
              ({(∨/⎕D∊1↑⍵)↓'⊃',⍵}name fmtidx i,⍴v)findnestedrefs oldroot (i⊃,v)
          :EndFor
      :EndIf
    ∇

    isOR       ←{(0∊⍴⍴⍵)∧1=≡⍵}
    isScripted ←{0::0 ⋄ 1⊣⎕SRC ⍵}
    startsWith ←{⍵≡(⍴⍵)↑⍺}
    stemOf     ←{⍵↓⍨-⊥⍨'.'≠⍵}
    rootws     ←{⍵.##}⍣≡

    ∇ name findrefsof (oldroot ref);refs;names;mf;n;v;rdf;pdf;salt;bad;stem;i;b;o;root;t
     ⍝ Manipulates FOUND, NAMES, LOOPS, XWS - see FINDREFS for details
     ⍝ Uses NA (max # aliases)

      →(ref∊⎕THIS)⍴0 ⍝ Don't include wherever this code is!
     
      COUNT+←1
     
      :If ref∊STACK             ⍝ Loop!
          PATHS←PATHS,⊂(-(⌽STACK)⍳ref)↑STACK ⍝ Register this ref as member of a loop
      :EndIf
      
      :If 2=≢⍴rdf←ODF ref 
          NOTES,←⊂'Not followed: ',name ⋄ →0
      :EndIf
      stem←stemOf rdf
      
      :If FINDXWS
      :AndIf ((≢t)↑name)≢t←⍕rootws ref
          XWS,←⊂name,' ',⍕ref
      :EndIf

      :If (⍴FOUND)≥i←FOUND⍳ref  ⍝ Been here before!
         ⍝ These are aliases to the same ref. This could go on almost forever in namespaces the way things are right now.
          {}?'too many references?'/⍨222<n←⍴names←i⊃NAMES
          →0 If(2=+/STACK=ref)∨(1<n)∧∨/{n≡((⍴n←(⍵⍳' ')↑⍵)↑name)}¨names  ⍝ Coming around again?
          (i⊃NAMES),←⊂name      ⍝ Register the name (alias)
      :Else
          FOUND,←ref
          salt←('.SALT_Data'≡¯10↑name)∧rdf≡(¯9↓name),'[Namespace]'
        ⍝ Check the name. Mention the display form if it is not the same.
          NAMES,←⊂,⊂name,(salt<name≢rdf)/1⌽') (DF=',rdf 
      :EndIf
     
      STACK,←ref
     
      :If </name⍳'⊃(' ⋄ name←'(',name,')' ⋄ :EndIf
     
      :If ~0∊⍴names←ref.⎕NL ¯9.1 9.2 9.4 9.5   ⍝ check refs
      :AndIf isScripted ref              ⍝ is this a scripted space?
      :AndIf 1∊bad←((name,'.')∘,¨names){⍺≡⍵:0 ⋄ ~'['∊⍵}¨o←ODF¨v←ref⍎¨names
      :AndIf 1∊bad←(2=≢∘⍴¨o)∨bad\isScripted¨bad/v
          NOTES,←⊂'These children of ',rdf,' are not followed:',⍕bad/names
          names←(~bad)/names
      :EndIf
     
      :If bad←~(¯1↓stemOf rdf)startsWith⍨pdf←ODF ref.##  ⍝ check the parent?
          NOTES,←⊂rdf,'''s parent is unusual: ',pdf
          names,←⊂pdf
      :EndIf
      :If 0∊⎕NC(~∨\'.['⍷pdf)/pdf
          NOTES,←⊂((1+bad)⊃(name,'''s parent')' and'),' is no longer referenced!'
      :EndIf
     
     ⍝ Look for missing Interfaces or Base classes
      :If 9.4∊⎕NC⊂name
          :If 1∊b←~bad←9≠⌊⎕NC n←⍕¨v←∊⎕CLASS ref
              (b/bad)←(b/v)≠⍎¨b/n  ⍝ same class but is it the same ref?
          :EndIf
          :If ∨/bad
              NOTES,←⊂rdf,'''s base class',((2⌊+/bad)⊃' is' 'es are'),' missing:',⍕bad/n
          :EndIf
      :EndIf
     
      :For n :In names~(((⎕SE.SALTUtils.DEBUG>0)∧ref=#)/⊂'THIS') ⍝,(0=ref.⎕NC names)/names
          (name,'.',n)findrefsof oldroot (ref⍎n)
      :EndFor
      :If 0≠⍴names←ref.⎕NL ¯2.1 2.2         ⍝ and variables
      :AndIf 0≠⍴names←(0.6≠1||ref.⎕NC names)/names
          names←({6::0 ⋄ 326∊⎕DR ref⍎⍵}¨names)/names
          :For n :In names
              (name,'.',n)findnestedrefs oldroot (ref⍎n)
          :EndFor
      :EndIf
     
      STACK←¯1↓STACK
    ∇

    ∇ r←name fmtidx rarg;shape;i;d;p;nz;s
     ⍝ Format index into ravel as index into matrix
      i←⊃rarg ⋄ shape←1↓rarg ⋄ d←'⊃'=1↑name
      :If ∨/1↓s←1 0=⍴shape
          r←(s[1]/(⍕i-~##.THIS.⎕IO),'⊃'),name
      :Else
          r←'[',(⍕##.THIS.⎕IO+shape⊤i-1),']'
          ((r=' ')/r)←';'
          p←d∧nz←0<⍴shape
          r←(p/'('),name,(p/')'),nz/r
      :EndIf
    ∇

    :Section TEST

    ∇ r←Test dummy;n1;n2;t;tn;Dc
      :Trap r←0
          ⎕EX'n1' ⋄ 'n1'⎕NS''
          n1.L←n1               ⍝ loop
          r,←3=2 3⊃⎕VFI⊃↓t←⎕SE.UCMD'findrefs n1'
     
          ⎕EX'n2' ⋄ 'n2'⎕NS''
          n2.r←n1 ⋄ n1.p←n2     ⍝ another loop
          r,←10=2 3⊃⎕VFI⊃↓t←⎕SE.UCMD'findrefs n1'
     
          Dc←n1.⎕NS''            ⍝ Dc refers to a child of a defunct ns
          ⎕EX'n1'
          r,←1∊'parent is no longer'⍷t←⎕SE.UCMD'findrefs Dc'
     
          n1←(⎕NS'').⎕FIX':namespace x' ':endnamespace'
          ⎕EX'n2' ⋄ 'n2.A'⎕NS'' ⋄ n1.y←n2.A ⋄ ⎕EX'n2'
          r,←2=2 3⊃⎕VFI⊃↓t←⎕SE.UCMD'findrefs n1'
          r,←1∊'parent is no longer'⍷t
     
         ⍝ This next test requires /tmp to exist
          ⎕EX 2 2⍴'n1n2'                     ⍝ create a class whose derived
          #.⎕FIX':class Bc' ':endclass'      ⍝ counterpart is NOT copied
          #.⎕FIX':class Dc:Bc' ':endclass'   ⍝ over with )COPY
          0 ⎕SAVE t←'/tmp/testfindref.dws'
          #.⎕EX'Dc'
          'Dc'⎕CY t ⍝ bring in the derived class WITHOUT its derived part
          r,←1∊'base class is miss'⍷t←⎕SE.UCMD'findrefs' ⍝ start from here
     
         ⍝ Create an empty array of classes
          #.Ac←0⍴¨Dc(⎕NEW Dc)
          #.⎕EX 2 2⍴'DcBc' ⋄ ⎕EX 2 2⍴'DcBc'
          r,←1∊'Ac[2]'⍷t←⎕SE.UCMD'findrefs' ⍝ start from here
          #.⎕EX'Ac'
     
          ⎕EX'n1' 'n2' ⋄ 'n1'⎕NS'' ⋄ 'n2'⎕NS''
          n2.Z←n1.⎕FIX':namespace x' ':endnamespace'
          r,←2=2 3⊃⎕VFI⊃↓t←⎕SE.UCMD'findrefs n2'
     
          r←1↓r ⍝ remove bad flag
      :EndTrap
    ∇

    :EndSection

:EndNamespace ⍝ findrefs  $Revision: 1519 $
