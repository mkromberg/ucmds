:Namespace efa ⍝ V3.12
⍝ Changes the associations of .dws, .dyapp, .apl? and .dyalog files
⍝
⍝ 2022 01 20 MKrom: Complete rewrite for v18.2
⍝ 2022 01 21 MKrom: Fix #8 Tweak display in GUI
⍝ 2022 01 21 MKrom: Fix #7 Classic 32 displays as Unicode 32 in GUI
⍝ 2022 01 22 MKrom: Fix #11 VALUE ERROR with .NET Core
⍝ 2022 01 22 MKrom: Fix #10 Unable to close the form
⍝ 2022 01 22 MKrom: Fix #9 Caption too long
⍝ 2022 01 28 Adam:  Report selected version, show correct current version, text and help, work around [19652]
⍝ 2022 01 31 Adam:  Include missing flags in syntax spec
⍝ 2022 02 01 Adam:  allow -source=load, textual changes
⍝ 2022 02 03 MKrom: Fix #22 dyalogscript.ps1 moved in 18.2
⍝ 2022 02 05 MKrom: v3.09 Fix #19 #20 #21: allow "current" and improve "status" output
⍝ 2022 02 07 Adam:  Update documentation accordingly, and show more status
⍝ 2022 02 24 Adam:  note about launching admin
⍝ 2022 03 01 MKrom: "dyalog"→"source"

⍝∇:require =\WinReg.dyalog


    ⎕ml←⎕io←1
    DESC←'Configure Microsoft Windows to associate directories and files with a specific Dyalog instance (optionally through a GUI)'

    CMD←' '~⍨NAME←'FileAssociations'
    CR LF←⎕UCS 13 10

    PreviewKey   ←'{8895b1c6-b41f-4c1c-a562-0d564250836f}'
    PreviewSource←'{b0b3fddb-41f2-47d5-9aa3-388d299a81a7}'
    PreviewWS    ←'{8eca1a43-ce27-48db-acbc-2f763a9a9c5e}'

    FileTypes    ←'dcfg' 'dws' 'dyalog' 'dyapp' 'dyalogscript'
    FileTypeOpts ←'er'   'rl'  'elr'    're'    're'           ⍝ edit load run, 1st is default
    FileTypeDescs←'Dyalog '∘,¨'Configuration' 'Workspace' 'APL Source' 'SALT Application' 'APL Script'
    Actions←'Edit' 'Load' 'Run'
    ActionLabels←'Edit' 'Load with Dyalog' 'Run with Dyalog'
    TextTypes    ←'dcfg' 'dyapp' 'dyalogscript' ⍝ // should this not be all but .dws?
    ⍝ // and maybe .dcfg should be application/javascript

    Tags         ←'config' 'dws' 'source' 'dyapp' 'script'
    DirKeys      ←'Directory' 'Directory\Background'
    FileExtns    ←'.dyalog' '.dcfg' '.dyapp' '.dws', '.apl'∘,¨'cfinos'  ⍝ NB no .apla for now
    ExtnTypes    ←'dyalog'  'dcfg'  'dyapp'  'dws',5 1/'dyalog' 'dyalogscript'

    HKCR←  'HKEY_CLASSES_ROOT\'                   ⍝ Classes "for all users" (no longer used)
    HKLMSC←'HKEY_LOCAL_MACHINE\Software\Classes\' ⍝ Classes for all users
    HKCUSC←'HKEY_CURRENT_USER\Software\Classes\'  ⍝ Classes for the current user

    Cap1st←1∘⎕C@1                                 ⍝ 1st letter uppercase
    GetVersion←{1↓1⍕⊃(//)⎕VFI ⍵}                  ⍝ Get version number of APLVersion string
    ExistingRegs←{⍵/⍨##.WinReg.DoesKeyExist¨⍵}    ⍝ Filter list of registry keys
    Hex←{'0123456789abcdef'[1+⍵]}

      VersionIDs←{                                ⍝ nn.n[Ubb] format from APL version name
          2≤|≡⍵:∇¨⍵
          vers←GetVersion ⍵
          tail←'CU'[1+1∊'Unicode'⍷⍵]
          tail,←'32' '64'[1+1∊'-64'⍷⍵]
          ∊vers,(~tail∊⊂'U64')/tail
      }

    ∇ v←defU64 APLversion input;nums;bit;vno;ucs;curvno;defU64;showC32
     ⍝ Returns an APL version specification matching the format used in the registry (or with added Classic and -32 if showC32) based on arg
     ⍝ Argument is any combination of the following:
     ⍝ '##' or '##.#' ⍝ Version number, e.g. '14' or '14.1'
     ⍝ 'C' or 'U'     ⍝ Classic/Unicode edition of current or specified version
     ⍝ '32' or '64'   ⍝ 32/64 bit version of current or specified version
     
      input←,⍕input
      input[1↓('.'=input)/⍳⍴input]←' '          ⍝ Remove all but first .
      input←('32|64' '\pL'⎕R' \u& '⍠1)input     ⍝ 32.1 ←→ 32 .1 ⋄ Uppercase and surround all chars with spaces
     
      nums←↑(//)' -/'⎕VFI input
      :If defU64
          ucs←' Unicode'/⍨'C'≠⍬⍴input∩'UC'          ⍝ If a U occurs before the first C
          bit←'-64'/⍨~32∊nums
      :Else
          ucs←' Unicode'/⍨'U'=⍬⍴input∩'UC'          ⍝ If a U occurs before the first C
          bit←'-64'/⍨64∊nums
      :EndIf
      ucs,←' Classic'/⍨0=≢ucs
      bit,←'-32'/⍨0=≢bit
     
      vno←|⍬⍴nums~32 64                         ⍝ Don't mistake 32 and 64 for ver nums
      vno÷←10*¯1+1⌈⌊10⍟0.1⌈vno                  ⍝ 141 ←→ 14.1
      vno÷←10*33≤vno                            ⍝ 33 ←→ 3.3
      vno←(1,⍨3+×⌊10⍟0.01⌈vno)⍕vno              ⍝ Include exactly one decimal
     
      v←vno,ucs,bit
    ∇

    :Section UCMD

    ∇ r←List;parse
      r←⎕NS''
      parse←'1SL -preview -user=current all -dir=show hide '
      parse,←'-workspace=run load -dyapp=run edit -script=run edit'
      parse,←'-config=edit run -source=edit run load '
      parse,←'-confirm -nobackup -qa_mode'
     
      r.(Name Desc Group Parse)←CMD DESC'MSWIN'parse
      r/⍨←⎕SE.SALTUtils.WIN
    ∇

    ∇ r←level Help Cmd;nl;h
      h←'    ]',Cmd,' [<instance>|status|details|remove|backup] '
      h,←'[-preview] [-dir={show|hide}] [-workspace={run|load} [-script={run|edit}] [-dyapp={run|edit}] '
      h,←'[-source={edit|run|load}] [-config={edit|run}] [-user={current|all}] [-nobackup] [-confirm]'
      r←DESC,nl,h,nl←⎕UCS 13
      :If level=0
          r,←nl
          r,←']',Cmd,' -?? ⍝ for details and examples',nl
      :Else
          r,←nl,'Argument is one of:',nl
          r,←'    ""          use a GUI to select settings (limited functionality)',nl
          r,←'    <instance>  associate with <instance> ("current" OR version, edition, bit-width; default edition and bit-width: Unicode and 64) '
          r,←'and reset all actions to their default values',nl
          r,←'    "status"    brief report of current associations and default actions',nl
          r,←'    "details"   full report of current associations and default actions',nl
          r,←'    "remove"    remove all current associations',nl
          r,←'    "backup"    export current associations to .reg file',nl
          r,←nl
          r,←'    <instance> must be one of:',nl
          r,←'       ',nl,⍨⍕VersionIDs InstalledVersions
          r,←'    These can be specified in any order and either fully or partially using shorthand:',nl
          r,←'        ## or ### or ##.#    Version number, for example 14 or 141 or 14.1 (default minor version is .0)',nl
          r,←'        C or U               Classic/Unicode edition (default: Unicode)',nl
          r,←'        32 or 64             32/64 bit-width (default: 64-bit)',nl
          r,←nl
          r,←'-preview                 display required changes but do not apply them',nl
          r,←'-dir={show|hide}         show or hide actions for directories (v18.2 or later only; default: show)',nl
          r,←'-config={edit|run}       set default action for configuration files (.dcfg; default: edit)',nl
          r,←'-source={edit|run|load}  set default action for source files (.apl? except .apls; default: edit)',nl
          r,←'-workspace={run|load}    set default action for workspaces (default: run)',nl
          r,←'-script={run|edit}       set default action for script files (.apls; default: run)',nl
          r,←'-dyapp={run|edit}        set default action for (deprecated) .dyapp files (default: run)',nl
          r,←'-user={current|all}      decide whether to work on HKEY_CURRENT_USER or HKEY_LOCAL_MACHINE (default: current if HKCU has settings, otherwise all) ',nl
          r,←'                           NOTE:  "all" needs administrative privileges; if necessary, ]',Cmd,' will ask to launch an elevated session',nl
          r,←'-nobackup                skip backup file (see warning below) when making changes',nl
          r,←'-confirm                 display proposed changes and ask for confirmation before proceeding',nl
          r,←nl
          r,←'Example:',nl
          r,←'    To see the current associations and default actions:',nl
          r,←'        ]',CMD,' status',nl
          r,←'    To set associations to the current instance:',nl
          r,←'        ]',CMD,' current',nl
          r,←'    To set associations to Dyalog version 17.1, 32-bit, Classic edition, while making APL functions run when double-clicked, for all users:',nl
          r,←'        ]',CMD,' 17.1C32 -source=run -user=all',nl
     
      :EndIf
     
     
      h←'WARNING:  Inappropriate associations can lead to unexpected '
      h,←'and ill-defined behaviour in Microsoft Windows'' handling of Dyalog files. '
      h,←'By default, this utililty saves the affected registry entries to a time-stamped '
      h,←'.reg file before making any changes. Double-click this file to restore any associations that were changed after the indicated time.'
      r,←nl,h
    ∇

    ∇ rc←Run(Cmd Args);defaults;t;switches;reg
     
      reg←(1+##.WinReg.DoesKeyExist HKCUSC,'dwsfile')⊃'all' 'current' ⍝ -user=current if current settings exist
     
      defaults←reg'show','edit' 'run' 'open'['ero'⍳⊃¨FileTypeOpts]
      switches←'user' 'dir' 'config' 'workspace' 'source' 'dyapp' 'script'
      t←Args.(user dir dcfg dws dyalog dyapp dyalogscript)←defaults{0≡⍵:⍺ ⋄ ⍵}¨⎕C Args⍎⍕switches
      ⍝ ↑↑↑ change human-friendly switch names to file type names used in registry to simpify the rest of the code
      Args.nondefault←(defaults≢¨t)/switches ⍝ record names of switches with non-default values
      Args._1←1 ⎕C Args._1 ⍝ Uppercase U and C in version ids
     
      rc←Do Args
    ∇

    ∇ r←GenUCMD Args;args;switches;swd;vals
      ⍝ Re-create UCMD
      args←'_'=⊃¨(swd←Args.SwD)[;1]
      switches←(~args)∧0≢¨swd[;2]
      vals←switches/swd[;2]
      vals←((~vals∊1)/¨'=',¨⍕¨vals)
      r←CMD,(¯1↓⍕args/swd[;2]),∊' -'∘,¨(switches/swd[;1]),¨vals
    ∇

    :EndSection UCMD

    ∇ rc←Do Args;REG;ivers;vers;ipaths;path;vernum;opts;str;bin;del;msg;old;new;ni;oi;common;keys;t;lastpath;g;lastUpath;sel;validcmd;validvers;file
      ⍝ The main function (note the useful comment!)
     
     RESTART:
      REG←('all' 'current'⍳⊂Args.user)⊃HKLMSC HKCUSC
     
      :If (Args.user≡'all')∧~IsUserAnAdmin
          t←'Select Yes to launch an additional APL process with administrative rights, and rerun the command.' ''
          t,←('If you select No but wish to perform the operation for the current user, include "-user=current" on the ',CMD,' command line.')''
          :If ~Args.qa_mode
          :AndIf 'Adminstrative privileges required for -user=all'MsgBoxYN t
              Args.SwD[Args.SwD[;1]⍳⊂'user';2]←⊂'all'
              →0⊣rc←LaunchAdminProcess GenUCMD Args
          :EndIf
          Args.SwD[Args.SwD[;1]⍳⊂'user';2]←⊂'current'
          →0⊣rc←↑'Aborted. Try:' ''('      ]',GenUCMD Args)
      :EndIf
     
      :If Args._1≡'DETAILS'
          :If 0=≢rc←⍕¨Show 1
              rc←'No Dyalog file associations found in ',REG
          :EndIf
          →0
      :EndIf
     
      ivers←InstalledVersions        ⍝ A vector of all installed versions of Dyalog APL (handles 11.0 onward)
      g←⍒vers←0 APLversion¨ivers     ⍝ nn.n[-Ubb] format
      (vers ivers)←{⍵[g]}¨vers ivers ⍝ Descending order
     
      ipaths←##.WinReg.GetString¨'HKEY_CURRENT_USER\'∘,¨ivers,¨⊂'\dyalog' ⍝ A vector of the installation directories of installed versions
      ipaths{⍺,⍵~⊃⌽⍺}¨←'\' ⍝ add trailing \ if missing
     
      Args.vers←vers                 ⍝ BuildReg and UpdateReg need it
      Args.lastUpath←(1⍳⍨~'C'∊¨vers)⊃ipaths,⊂'' ⍝ highest installed Unicode version - for preview
     
      :If 0≡Args._1 ⍝ No arguments
          :If 0=⊃t←SelectGui vers(CurrentAssociations 0)Args
              →0⊣rc←'Operation cancelled'
          :Else
              Args←2⊃t
              ⎕←↑'Processing:' ''('      ]',GenUCMD Args)
              →RESTART
          :EndIf
      :EndIf
     
      :If Args._1≡'CURRENT' ⍝ Replace current by the current version ID
          t←'#'⎕WG'APLVersion'
          t←({(¯1+2⊃⍸⍵='.')↑⍵}2⊃t),' ',('64'∩1⊃t),(82=⎕DR' ')/' Classic'
          Args._1←1 APLversion t
      :EndIf
     
      :If validcmd←(⊂Args._1)∊'STATUS' 'DETAILS' 'REMOVE' 'BACKUP'
          validvers←0
      :Else
          Args._1←1 APLversion Args._1
          validvers←(⊂Args._1)∊vers
      :EndIf
     
      :If (Args._1≡'STATUS')∨~validcmd∨validvers
          rc←(Args._1≢'STATUS')/('*** Invalid instance: ',(⍕⊃Args.Arguments),' ***')''
          rc,←⊂''
          rc,←⊂4⌽' ────── ',{'Status for ',(1 ⎕C ⍵),' user',(⍵≡'all')/'s'}Args.user
          rc,←⊂''
          rc,←'Installed instances are:' ''('     ',⍕VersionIDs vers)''
          rc,←CurrentAssociations 1
          rc←↑rc
     
      :ElseIf Args._1≡'REMOVE'
          keys←1 ReadReg REG      ⍝ Find existing keys
          rc←Args DeleteReg keys
     
      :ElseIf Args._1≡'BACKUP'
          rc←Backup Args
     
      :Else
          :If ~(⊂'RunTests')∊⎕SI
              ⎕←'Selected instance: ',Args._1
          :EndIf
          vernum←⊃⊃⌽⎕VFI Args._1
          path←(vers⍳⊂Args._1)⊃ipaths,⊂'C:\Program Files\Dyalog\APL v.',Args._1,'\not installed\' ⍝ // might not need the fallback element
     
          (msg str bin del)←BuildReg path vernum REG Args
          :If 0≠≢msg
              →0⊣rc←msg
          :EndIf
     
          rc←Args UpdateReg(str⍪bin)del
      :EndIf
    ∇

    ∇ r←IsUserAnAdmin;IsUserAnAdmin
     ⍝ check if this process is being "Run as Administrator"
      :Trap r←0
          r←⍎⎕NA'I Shell32|IsUserAnAdmin'
      :EndTrap
    ∇

    ∇ rc←LaunchAdminProcess ucmd;cmd;psi;z
      ⎕USING←'System,System.dll'
      cmd←2 ⎕NQ'.' 'GetCommandlineArgs'
      cmd,←⊂'LX=⎕←↑⍪'''' ''Administrative process started. Now re-run:'' '''' ''      ]',ucmd,''''
      psi←⎕NEW Diagnostics.ProcessStartInfo(1↑cmd)
      ⍝ work around [19652] interpreter reports command line arguments without quotes
      psi.Arguments←⍕'^\w+=".*"$|^-\w+$' '^\w+=.*$'⎕S{⍵.PatternNum:⍵.Match((⍳↑⊣),1 ⎕JSON⍳↓⊣)'=' ⋄ ⍵.Match}1↓cmd
      psi.Verb←'runas' ⍝ Request elevation
      z←Diagnostics.Process.Start psi
      rc←'Administrative process launched.'
    ∇

    ∇ r←InstalledVersions;sk;mask;hkcu;sd
      ⍝ Retrieve the list of installed versions of Dyalog APL
     
      hkcu←'HKEY_CURRENT_USER\'
      sd←'Software\Dyalog\'
      sk←##.WinReg.GetAllSubKeyNames hkcu,sd
      mask←1∊¨'Dyalog APL/'∘⍷¨sk
      r←(⊂sd),¨mask/sk
    ∇

    ∇ rc←Show mode;rc
      ⍝ Read registry and clean it up a bit.
      ⍝ "mode" was never implemented idea to do more formatting.
     
      rc←0 ReadReg REG
      rc←(0≠≢¨rc[;3])⌿rc                    ⍝ Drop empties
      rc[;2]←rc[;2]↓⍨¨¯2×(¯2↑¨rc[;2])∊⊂'\\' ⍝ Drop trailing \\ from key names
      rc←{⍵[⍋⍵;]}0 1↓rc
    ∇

    ∇ reg←keynames ReadReg REG;extns;keys;preview;dirkeys;extncls;user;all;apps;userkeys
      keys←REG∘,¨(FileTypes,¨⊂'file'),'Applications\dyalog.exe' 'Applications\dyaedit.exe'
      preview←REG∘,¨'CLSID\'∘,¨PreviewSource PreviewWS
      dirkeys←REG∘,¨,DirKeys∘.,'\shell\'∘,¨'DyalogLoad' 'DyalogRun'
      extncls←REG∘,¨FileExtns
     
      userkeys←'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\'∘,¨FileExtns
      user←(ExistingRegs userkeys),¨⊂'\OpenWithList'
     
      reg←ExistingRegs(all←keys,preview,dirkeys,extncls),user
     
      :Select keynames
      :Case 0 ⍝ Get the actual values
          reg←⊃⍪/{⍵∧.=' ':0 3⍴⊂'' ⋄ ##.WinReg.GetTreeWithValues ⍵}¨reg
     
      :Case 1 ⍝ Existing registies - already done
     
      :Case 2 ⍝ All potential keys
          reg←userkeys,all
      :EndSelect
    ∇

    ∇ reg←reg KeysOnly keys;key;m;t
    ⍝ Trim registry data to list 1st level of subkeys for keys
      :For key :In keys
          m←((≢key)↑¨reg[;1])∊⊂key
          t←∪{(¯1+⍵⍳¨'\')↑¨⍵}(1+≢key)↓¨m/reg[;1]
          reg←((~m)⌿reg)⍪(⍪(key,'\')∘,¨t),⎕NULL
      :EndFor
    ∇

    ∇ r←CurrentAssociations fmt;keys;labels;i;m;n;defaults;t;dir
      ⍝ Report on existing associations found in the registry
     
      ⍝ Set up a list of keys representing different kinds of association
     
      keys←PreviewSource PreviewWS,¨⊂'\LocalServer32'
      labels←'Workspace Preview' 'Source Preview'
      keys,←,FileTypes∘.,'file\shell\Run\command' 'file\shell\Edit\command' 'file\shell'
      labels,←3/FileTypes
      keys,←⊂(⊃DirKeys),'\shell\DyalogLoad\command'
      labels,←⊂'Directories'
     
      r←Show 0                 ⍝ read all the keys
      i←(1∊¨keys∘.⍷r[;1])⍳⍤1⊢1 ⍝ search for "our" keys
      m←i≤≢r
      r←(m/labels),r[m/i;,2]   ⍝ keys and values of interest
      defaults←(r[;2]∊'Edit' 'Run' 'Load')⌿r
      r←(1∊¨'Dyalog APL'∘⍷¨r[;2])⌿r
      r[;2]←VersionIDs r[;2]   ⍝ convert folder names to nn.n[-Ubb] format
      r←r[r[;1]⍳∪r[;1];],⊂''   ⍝ remove duplicates, add default column
      r[r[;1]⍳defaults[;1];3]←('default action is '∘,¨defaults[;2])
      t←{(~⍵∊r[;1])/⍵}FileTypes,⊂'Directories'
      r←r⍪(⍪t),⍤1⊢'none' ''
     
      dir←r[;1]⍳⊂'Directories'
      :If r[dir;2]≡⊂'none'
          r[dir;3]←⊂'(menu items hidden)'
      :Else
          r[dir;3]←⊂'(menu items shown)'
      :EndIf
     
      :If ~∧/'Source Preview' 'Workspace Preview'∊r[;1]
          r⍪←'Source Preview' 'none' '(disabled)'
          r⍪←'Workspace Preview' 'none' '(disabled)'
          r⌿⍨←≠⊣/r
      :Else
          r[r[;1]⍳'Source Preview' 'Workspace Preview';3]←⊂'(enabled)'
      :EndIf
     
      r[⍸r[;1]∊⊂'dyalog';1]←⊂'source'
      r←r[⍋r;]
      →fmt↓0
     
      r←'Current associations:' '',↓⍕(⊂'   '),r
    ∇

    ∇ (msg str bin del)←BuildReg(path vernum REG opts);types;str;bin;mask;Text;dws;dyapp;dyalog;Icon1;script;pv;clsid;dn;type;extns;name;key;icons;values;default;subkeys;delete;todelete;i;labels;dir;EditCmd;PreviewCmd;RunCmd;RunShCmd;LoadCmd;DyalogIcon;EditorIcon;actionicons;subs;cmds;editcmd;loadcmd;runcmdEditWithNotepad;ft;pvnum;pvpath;versions;Version;ver;shell;RunDyappCmd
    ⍝ Builds data to be written to registry
     
      str←bin←0 2⍴'' ⍝ String and Binary values to set
      del←⍬          ⍝ Keys to be deleted
      msg←''         ⍝ Empty if OK, else error message
     
      EditWithNotepad←'notepad "%1"'
     
      RunCmd←'"',path,'dyalog.exe" LOAD="%1"'
      RunDyappCmd←'"',path,'dyalog.exe" DYAPP="%1"'
      RunShCmd←'powershell -File "',path,'scriptbin\dyalogscript.ps1" "%1" %*'
      LoadCmd←'"',path,'dyalog.exe" -x LOAD="%1"'
     
      DyalogIcon←'"',path,'dyalog.exe",0'
      EditorIcon←'"',path,'dyaedit.exe",2'
      actionicons←(DyalogIcon EditorIcon)[1+Actions∊⊂'Edit']
      Version←⍕10×vernum ⍝ For "version" properties
     
      ⍝ Version-dependent commands
     
      :If vernum≥17
          EditCmd←'"',path,'dyaedit.exe" "%1"'
      :Else ⍝ Before v17.0, the editor was handled differently
          EditCmd←'"',path,'dyalogrt.exe" -EDITONLY "%1"'
          (RunCmd LoadCmd)←('LOAD='⎕R'')RunCmd LoadCmd
      :EndIf
     
      :If opts.qa_mode ⍝ When doing QA...
          (pvnum pvpath)←vernum path                     ⍝ Always use the requested version
      :Else
          pvnum←⊃2⊃⎕VFI GetVersion pvpath←opts.lastUpath ⍝ Latest installed Unicode version
      :EndIf
     
      :If pvnum≥17
          PreviewCmd←'"',pvpath,'dyaedit.exe" -PREVIEW'
      :Else
          PreviewCmd←'"',pvpath,'dyalogrt.exe" -PREVIEW'
      :EndIf
      PreviewCmd←(×≢pvpath)/PreviewCmd
     
      ⍝ --- Set up Previewers ---
      :If 'all'≡pv←'all' ⍝ This used to be controlled by an option (⊂opts.preview)∊'all' 'text'
          ⍝ Register preview for each file extension
          ft←FileExtns~(vernum<18 18.2)/'.dcfg' '.apls'  ⍝ dcfg from 18.0, script from 18.2
          extns←ft~(pv≢'all')/⊂'.dws'          ⍝ Only set up .dws preview if -preview=all
          str⍪←(REG∘,¨extns,¨'\'),⍪ExtnTypes[FileExtns⍳extns],¨⊂'file'
          str⍪←(~extns∊⊂'.dyapp')⌿(REG∘,¨extns,¨⊂'\shellex\',PreviewKey,'\'),⍪(PreviewSource PreviewWS)[1+extns∊⊂'.dws']
          ⍝ Register the two previewers
          :For clsid name :In (PreviewSource'Dyalog Script Preview Handler')(PreviewWS'Dyalog Workspace Preview Handler')
              key←REG,'CLSID\',clsid,'\'
              str⍪←(key∘,¨'DisplayName' 'Version' 'InProcHandler32\' 'LocalServer32\'),⍪name(⍕10×pvnum)'ole32.dll'PreviewCmd
              bin⍪←(key,'DisableLowILProcessIsolation')1
          :EndFor
      :EndIf
     
      ft←FileTypes~(vernum<18 18.2)/'dcfg' 'dyalogscript'  ⍝ dcfg from 18.0, script from 18.2
      ft,←(vernum≥18.2)/DirKeys                            ⍝ Only set up Directory shortcuts for v18.2 or later
     
      :For type :In ft
     
          :If dir←(⊂type)∊DirKeys  ⍝ Directory menu items are special
              key←REG,type,'\shell\'
              subkeys←'DyalogLoad' 'DyalogRun'
              ver←(type≡'Directory')/Version
              todelete←key∘,¨subkeys
              default←''              ⍝ No default for directories
              delete←opts.dir≡'hide'
     
          :Else                    ⍝ One of "our" file types
              key←REG,type,'file\'
              subkeys←('Edit' 'Load' 'Run')[i←'elr'⍳(FileTypes⍳⊂type)⊃FileTypeOpts]
              ⍝ ↑ Note we use "Load" as key name for the "Open with Dyalog" action
              ⍝ ↓ Do not set Load up for versions before 18.2 except for .dws
              subkeys~←((type≢'dws')∧vernum<18.2)/⊂'Load'
              ver←Version
              todelete←,⊂key
              default←Cap1st opts⍎type
              delete←'Off'≡default ⍝ Off is not currently an option but that might change
          :EndIf
     
          :If delete
              del,←todelete
              :Continue
          :EndIf
     
          labels←ActionLabels[i←Actions⍳('Dyalog'⎕R'')subkeys]
          icons←actionicons[i]
          (editcmd loadcmd runcmd)←EditCmd LoadCmd RunCmd
     
          ⍝ Implement Various Exceptions
          :If type≡'dyalogscript'
              labels←('Run with Dyalog'⎕R'Run')labels ⍝ scripts will not stop in the IDE (for now)
              runcmd←RunShCmd
          :ElseIf type≡'dyapp'
              editcmd←EditWithNotepad
              icons←(~labels∊⊂'Edit')/¨icons    ⍝ No icon for Edit since we use Notepad
              runcmd←RunDyappCmd
          :ElseIf type≡'dcfg'
              (loadcmd runcmd)←('LOAD='⎕R'CONFIGFILE=')loadcmd runcmd
          :ElseIf dir
              (loadcmd runcmd)←('\%1'⎕R'\%V')loadcmd runcmd
          :EndIf
     
          cmds←(editcmd loadcmd runcmd)[i]
     
          :If ~dir ⍝ We don't describe Dirs or set DefaultIcon for them
              key←REG,type,'file\'
              str⍪←(⊂key),FileTypeDescs[FileTypes⍳⊂type]
              str⍪←(0≠≢default)⌿1 2⍴(key,'shell\')default
              str⍪←(0≠≢⊃icons)⌿1 2⍴(key,'DefaultIcon\')((subkeys⍳⊂default)⊃icons)
          :AndIf (⊂type)∊TextTypes ⍝ Add hints for files considered to be text
              str⍪←(key∘,¨'Content Type' 'Perceived Type'),⍪'text/plain' 'text'
          :EndIf
     
          shell←(key←REG,type,(~dir)/'file'),'\shell\'
          subs←shell∘,¨subkeys
          str⍪←(subkeys≢¨labels)⌿(subs,¨'\'),⍪labels ⍝ Name each action (Edit/Open with Dyalog/etc)
          str⍪←(×≢¨icons)⌿(subs,¨⊂'\Icon'),⍪icons
          str⍪←((~dir)∧×≢ver)⌿1 2⍴(key,'\Version\')ver ⍝ filetypes have a single Version tag
          str⍪←(dir∧×≢ver)⌿(⍪subs,¨⊂'\Version\'),⊂ver  ⍝ Directory has one for each subkey
          EditCmd←'"',path,'dyaedit.exe" "%1"'
          str⍪←(subs,¨⊂'\command\'),⍪cmds
      :EndFor
    ∇

    ∇ rc←Args DeleteReg keys;file
      ⍝ implement deletion of selected keys
     
      :If Args.(confirm∨preview)
          ⎕←CMD,' would like to delete:'
          ⎕←⍪keys
          ⎕←''
          →Args.preview⍴0⊣rc←'Changes NOT applied'
     
          :If ~ProceedQ'Proceed (y/n)?'
              →0⊣rc←'No changes made'
          :EndIf
      :EndIf
     
      :If ~Args.nobackup
          →(0=⍴file←Backup Args)⍴0
          ⎕←'Backup written to ',LastBackupFile←file
      :EndIf
      rc←ApplyRegChanges keys ⍬
    ∇

    ∇ r←ProceedQ prompt;input
      ⍝ Get a y or n answer
     
      :Repeat
          ⎕←prompt ⋄ input←⍞
      :Until (⊂input~' ')∊,¨'YyNn'
      r←∨/'Yy'∊input
    ∇

    ∇ rc←Args UpdateReg(new del);old;m;remove;add;common;oi;ni;update;newkeys;new;i;v;file
     ⍝ ask user for confirmation if necessary, and call ApplyRegChanges if all OK
     
      old←Show'raw'
      old←old KeysOnly'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts' 'HKEY_CURRENT_USER\Software\Classes\Applications'
     
      new←new[⍋new;]
      newkeys←(-'\'=⊃∘⌽¨new[;1])↓¨new[;1] ⍝ drop trailing \
     
      (new old)←,¨¨new old ⍝ avoid disagreement on whether binary 1 is a scalar or vector
     
      remove←(~old[;1]∊newkeys)⌿old                        ⍝ keys which are no longer found
      remove←((~∨⌿⊃¨del∘.⍷remove[;1])⌿remove)⍪(⍪del),⎕NULL ⍝ keys explicitly requested to be deleted
     
      add←(~newkeys∊old[;1])⌿new                           ⍝ new keys
      common←newkeys∩old[;1]
      m←new[ni←newkeys⍳common;2]≢¨old[oi←old[;1]⍳common;2]
      update←new[m/ni;1],old[m/oi;2],new[m/ni;,2]          ⍝ common keys, old and new values
     
      ⍝ Logic to avoid downgrading the previewer
      :If ∨/m←(¯15↑¨update[;1])∊⊂'\LocalServer32\'
          v←1 APLversion¨GetVersion¨0 1↓m⌿update
          (m/m)←(v[;1]∊Args.vers)∧>/⍋⍤1⊢v ⍝ Entries which would "downgrade" the previewer
          update←(~m)⌿update
      :EndIf
     
      :If 0∧.=≢¨remove add update
          →0⊣rc←'No changes required to registry to use ',Args._1
      :EndIf
      →(0≠⍴rc←ConfirmRegChanges add remove update Args)⍴0
    ∇

    ∇ file←Backup Args;keys;txt;file;del;hdr;⎕USING
     
      ⎕USING←'Microsoft.Win32'
      :If 0={6::0 ⋄ ≢,Registry.Users}⍬
          ⎕←'Unable to take a backup: The available version of .NET does not provide a Registry class.'
          →0⊣file←''
      :EndIf
     
      txt←'; First clear out all Dyalog file association registry keys',CR,CR
      txt←,∊'[-'∘,¨(2 ReadReg REG),¨⊂']',CR
      keys←2 ReadReg REG
      txt,←CR,'; Then reinstate values',CR
      txt,←CR,∊MakeRegText¨keys
      hdr←'Windows Registry Editor Version 5.00',CR,CR
      hdr,←'; Backup file created by ]',CMD,(⊃' "at" %ISO%'(1200⌶)1 ⎕DT'J'),CR,CR
      txt←hdr,txt
      file←BackupFileName(739⌶0)
      (⊂txt)⎕NPUT file
    ∇

    ∇ ts←BackupFileName dir
    ⍝ Time Stamped .reg file name in specified dir
      dir,←'\'~⊃⌽dir       ⍝ Ensure final \
      ts←'0'∘,¨⍕¨⎕TS       ⍝ Pad 0s
      ts↑¨⍨←-4 2 2 2 2 2 3 ⍝ Chop
      ts←1↓∊'-',⍪ts        ⍝ Insert dashes
      ts,←'.reg'           ⍝ Append extension
      ts,⍨←dir,'efa-backup-'  ⍝ Prepend dir
    ∇

    ∇ rc←ConfirmRegChanges(add remove update Args);t;m;⎕PW;file
      ⍝ Confirm changes with the user if necessary
      ⍝ rc←empty to proceed or message to abort
     
      :If Args.(confirm∨preview)
          ⎕PW←1000
          ⎕←'In order to prepare for use of ',Args._1,' for ',(1 ⎕C Args.user)
          :If 0≠≢Args.nondefault
              t←1↓∊' ',¨Args.nondefault,¨'=',¨Args⍎¨Args.nondefault
              ⎕←'   (with non-default settings: ',t,')'
          :EndIf
          :If ~((⊂Args._1)∊Args.vers)
              ⎕←'   (NB: ',Args._1,' is not installed on this machine)'
          :EndIf
          ⎕←''
     
          :If 0≠≢remove
              ⎕←CMD,' would like to delete:'
              m←(remove[;2]∊⎕NULL)∨(326=⎕DR¨remove[;2])∧(⍕¨remove[;2])∊⊂' [Null] '
              (⊂'Registry key'),m⌿1↑⍤1⊣remove
              ⎕←⍪,'  ' '    = ',¨⍤1⊣(~m)⌿remove
              ⎕←''
          :EndIf
     
          :If 0≠≢add
              ⎕←CMD,' would like to add:'
              ⎕←⍪,'  ' '    = ',¨⍤1⊣add
              ⎕←''
          :EndIf
     
          :If 0≠≢update
              ⎕←CMD,' would like to modify:'
              ⎕←⍪,'  ' '   from: ' '     to: ',¨⍤1⊣update
              ⎕←''
          :EndIf
     
          →Args.preview⍴0⊣rc←'Changes NOT applied'
     
          :If ~ProceedQ'Proceed (y/n)?'
              →0⊣rc←'No changes made'
          :EndIf
     
      :EndIf
     
      :If ~Args.nobackup
          rc←'Backup failed. Please try again with -nobackup'
          →(0=≢file←Backup Args)⍴0
          ⎕←'Backup written to ',LastBackupFile←file
      :EndIf
      rc←ApplyRegChanges(remove[;1])(add⍪1 0 1/update)
      rc,←' User = ',Args.user,'.'
    ∇

    ∇ rc←ApplyRegChanges(delete set);i;t;key
      rc←∊,(⍕¨≢¨delete set),⍪' deleted, ' ' set.'
      :For i :In ⍳≢delete
          :If t←##.WinReg.DoesKeyExist key←i⊃delete
              t←##.WinReg.DeleteSubKeyTree key
          :ElseIf t←##.WinReg.DoesValueExist key
              t←##.WinReg.DeleteValue key
          :EndIf
          :If t≠0
              ⎕←'Failed to delete: ',key,' rc=',⍕t
          :EndIf
      :EndFor
     
      :For i :In ⍳≢set
          :Trap 11
              :If ' '≡⊃0⍴⊃set[i;2]
                  t←##.WinReg.PutString set[i;]
              :Else
                  t←##.WinReg.PutBinary set[i;]
              :EndIf
          :Else
              ⎕SIGNAL⊂('EN' 11)('Message'(⎕DMX.Message,1⌽')(Failed to set: ',key,' rc=',⍕t))
          :EndTrap
      :EndFor
    ∇

    :Section GUI

    ∇ (ok Args)←SelectGui(vers curr Args);Text;Y;X;vers;size;listx;neither;line1;i;type;dws;dyapp;dyalog;Applications;f;z;ok;users;selected;done;cap
    ⍝ Creates GUI
     
      Text←('Current associations for ',(1 ⎕C Args.user),(' user',(Args.user≡'all')/'s'),':')''
      Text,←FmtCurrent curr
      Text,←'' 'Select instance to associate:'
      cap←'Edit File Associations'
      vers←(⊂⍒vers)⌷vers
      listx←300⌊19×⍴vers
      size←(308+listx),365
     
      'f'⎕WC'Form'cap('Size'size)('Coord' 'Pixel')('Sizeable' 0)('MaxButton' 0)('MinButton' 0)
      'f.fnt'⎕WC ⎕SE.SALTUtils.Fonts.Message
      'f.fnt'⎕WS'Size' 16
      'f'⎕WS'Event'('Close' 1)
      'f'⎕WS'FontObj' 'f.fnt'
      'f.msg'⎕WC'Text'(↑Text)(10 15)
      'f.list'⎕WC'List'('Items'vers)('Posn'(165 30))('Size'(listx,300))('Selitems'(vers∊2↓curr[;2]))('Event' 'MouseDblClick' 1)
     
      'f.dir'⎕WC'Button' '&Show Windows Explorer context menu items for directories'((180+listx),15)('Style' 'Check')('State'(Args.dir≡'show'))
      'f.backup'⎕WC'Button' '&Create a backup of the relevant registry settings'((205+listx),15)('Style' 'Check')('State'(~Args.nobackup))
      users←'Current User'('All users ',(~IsUserAnAdmin)/' (requires admin rights)')
     
      'f.userlabel'⎕WC'Text' 'Set associations for:'((232+listx),15)
      'f.user'⎕WC'Combo'('Items'users)('SelItems'((Args.user≡'all')⌽1 0))('Posn'((230+listx),125))('Size' 30 200)
     
      'f.bapply'⎕WC'Button'('Caption' '&Apply')('Posn'((1⊃size)-40)100)('Size' 30 70)('Event' 'Select' 1)
      'f.bcancel'⎕WC'Button'('Caption' '&Cancel')('Posn'((1⊃size)-40)200)('Size' 30 70)('Event' 'Select' 1)
     
      ⎕NQ'f.bcancel' 'Gotfocus'
      :Repeat
          z←⎕DQ'f'
          ok←(⊂2↑z)∊('f.bapply' 'Select')('f.list' 'MouseDblClick')
          ok←ok∧1=+/f.list.SelItems
          :If ~done←ok∨(⊂z)∊('f.bcancel' 'Select')((,'f')'Close')
              cap MsgBoxAlert'Please select an instance.'
          :EndIf
      :Until done
     
      Args._1←⊃f.list.SelItems/vers
      Args.nobackup←~f.backup.State
      Args.dir←(1+f.dir.State)⊃'hide' 'show'
      Args.user←(f.user.SelItems⍳1)⊃'current' 'all' 'all'
      Args.SwD[Args.SwD[;1]⍳'_1' 'nobackup' 'user' 'dir';2]←Args.(_1 nobackup user dir)
      f.Close
    ∇

    ∇ r←FmtVersions vers;p
      r←(¯1+p←vers⍳¨'-')↑¨vers
      r←r,¨' ',¨(5⍴'64-bit Unicode' '64-bit Classic' '32-bit Unicode' '32-bit Classic')['U64' 'C64' 'U32' 'C32'⍳p↓¨vers]
    ∇

    ∇ Text←FmtCurrent curr;dws;dyapp;dyalog;script;dir;pv;i
      i←curr[;1]⍳'dws' 'dyapp' 'source' 'dyalogscript' 'Directories' 'Source Preview'
      (dws dyapp dyalog script dir pv)←(curr[;2],⊂'(none)')[i]
     
      Text←⊂'      Scripts             (.apls)                    ',script
      Text,←⊂'      Sources           (.apl?, .dyalog)     ',dyalog
      Text,←⊂'      SALT apps       (.dyapp)                ',dyapp
      Text,←⊂'      Workspaces    (.dws)                    ',dws
      Text,←⊂'      Directories                                     ',dir
      Text,←⊂'      Preview                                          ',pv
    ∇

    ∇ {r}←{title}MsgBoxInfo msg;m
    ⍝ Creates a message box
      :If 0=⎕NC'title' ⋄ title←NAME ⋄ :EndIf
      'm'⎕WC'MsgBox'title msg'info'
      r←⎕DQ'm'
    ∇

    ∇ {r}←{title}MsgBoxAlert msg;mb
      :If 0=⎕NC'title' ⋄ title←NAME ⋄ :EndIf
      'mb'⎕WC'MsgBox'('Caption'title)('Text'msg)('Style' 'Warn')('Btns' 'OK')
      r←⎕DQ'mb'
    ∇

    ∇ {r}←{title}MsgBoxYN msg;mb
      :If 0=⎕NC'title' ⋄ title←NAME ⋄ :EndIf
      'mb'⎕WC'MsgBox'('Caption'title)('Text'msg)('Style' 'Query')('Event'('MsgBtn1' 'MsgBtn2')1)
      r←'MsgBtn1'≡2⊃(⎕DQ'mb'),2⍴⊂''
    ∇

    :EndSection


    ∇ r←MakeRegText key;name;entry;ST;paths;pathnames;kind;obj;i;t;path;lastpath
     
      r←''
      →(0=≢ST←ReadTree key)⍴0
     
      r←'[',key,']',CR
      pathnames←ST[;1]
      ST[;1]←{(1-(⌽⍵)⍳'\')↑⍵}¨pathnames     ⍝ Values
      paths←(-1+⍴¨ST[;1])↓¨pathnames ⍝ Paths
      lastpath←key
     
      :For i :In ⍳≢paths
          (name kind obj)←ST[i;]
          entry←(lastpath≢path)/CR,'[',(⍕path←i⊃paths),']',CR
     
          :If 0=≢name ⋄ entry,←'@=' ⍝ default property
          :Else ⋄ entry,←'"',name,'"='
          :EndIf
     
          :Select t←⍕kind
          :CaseList 'Binary' 'None'
              entry,←'hex:',1↓,',',Hex⍉0 16⊤obj                        ⍝ hex:d4,a1,0g
          :Case 'MultiString'
              entry,←'hex(7):',1↓,',',2 2⍴⍤1⊢Hex⍉(4/16)⊤⎕UCS obj       ⍝ hex(7) with 00,00 as separator ⍝⍝⍝ ??? ASK DAN !!!
          :Case 'DWord'
              entry,←'dword:',Hex(8⍴16)⊤obj
          :Else  ⍝ SZ (String)
              entry,←'"','"',⍨('\\' '"'⎕R'\\\\' '\\"')obj              ⍝ in quotes, with \ and " as \\ and \"
          :EndSelect
          r,←entry,CR
          lastpath←path
      :EndFor
      r,←CR
    ∇

    ∇ ntd←ReadTree sourceKey;kind;name;sourceSubKey;user;obj;t;root;⎕USING;base;n;subKeyName;path
     ⍝ Read all the values from source and return a 3 col table of Name,Type,Data
     ⍝ The argument may be a string or a reference to a key
     ⍝ Ex:
     ⍝  ReadTree 'HKEY_CURRENT_USER\Software\ABC\Ver1'
     
      ntd←0 3⍴⍬
     
      :If ~0=≡sourceKey
          ⎕USING←'Microsoft.Win32'
          root←'HKEY_USERS' 'HKEY_CURRENT_CONFIG' 'HKEY_CLASSES_ROOT' 'HKEY_CURRENT_USER' 'HKEY_LOCAL_MACHINE'
          base←Registry.(Users CurrentConfig ClassesRoot CurrentUser LocalMachine)
          t←base[root⍳⊂(¯1+n←t⍳'\')↑t←sourceKey]
          sourceKey←t.OpenSubKey⊂n↓sourceKey
          →(⎕NULL≡sourceKey)⍴0
      :EndIf
     
      :For name :In sourceKey.GetValueNames
          obj←sourceKey.GetValue⊂name
          kind←sourceKey.GetValueKind⊂name
          path←(⍕sourceKey),'\',name
          ntd⍪←path kind obj
      :EndFor
     
     ⍝ For Each subKey:
     ⍝ - Call myself on each subKey
      :For subKeyName :In sourceKey.GetSubKeyNames
          sourceSubKey←sourceKey.OpenSubKey⊂subKeyName
          ntd⍪←ReadTree sourceSubKey
          sourceSubKey.Close
      :EndFor
      sourceKey.Close
    ∇

    :Section Test

    ∇ {msg}assert flag
      ⎕SIGNAL(0∊flag)/11
    ∇

    ∇ r←RunTests;ver;z;ivers;REG;assoc;pv;backup;i;switches
     
      REG←(i←1+#.WinReg.DoesKeyExist HKCUSC,'dwsfile')⊃HKLMSC HKCUSC
      switches←' -user=',i⊃'all' 'current'
      switches,←' -qa_mode' ⍝ Required to block certain behaviours during testing
     
      ⎕←'Running tests with',switches
     
      ver←GetVersion 2 ⎕NQ'.' 'GetEnvironment' 'Dyalog'
      'Tests require version 18.2 64 Unicode'⎕SIGNAL('18.2'≢ver)/11
     
      z←⎕SE.UCMD CMD,' ',ver,' -preview',switches
      'Please set ]fileassociations current -qa_mode first'⎕SIGNAL('No changes required'≢19↑z)/11
     
      ivers←InstalledVersions
      'Version 18.0 needs to be installed'⎕SIGNAL((⊂'18.0')∊ivers)/11
     
      ⍝ --- Validate v18.2 Associations
      assoc←CurrentAssociations 0
      assert 8=≢assoc
      pv←(assoc[;1]⍳⊂'Workspace Preview')⊃assoc[;2]
      assert∧/((assoc[;1]∊'dcfg' 'dws' 'dyalog' 'dyapp' 'dyalogscript' 'Directories')/assoc[;2])∊⊂'18.2U64' ⍝ Most associations gone
     
      ⍝ --- Take a backup, switch to and verify 18.0, and finally restore to 18.2 using the backup
     
      backup←⎕SE.UCMD CMD,' backup',switches
     
      z←⎕SE.UCMD CMD,' 18.0 -nobackup',switches ⍝ Switch to v18.0 and validate the resulting associations
     
      assoc←CurrentAssociations 0
      assert 8=≢assoc
      assert∧/((assoc[;1]∊'dcfg' 'dws' 'dyalog' 'dyapp')/assoc[;2])∊⊂'18.0U64'    ⍝ Core associations switched
      assert∧/((assoc[;1]∊'Workspace Preview' 'Source Preview')/assoc[;2])∊⊂pv    ⍝ Preview should still use latest
      assert∧/((assoc[;1]∊'Directories' 'dyalogscript')/assoc[;2])∊⊂'none'        ⍝ Not supported by 18.0
     
      ⎕CMD'reg import "',backup,'"'                                                ⍝ Restore the backup
      z←⎕SE.UCMD CMD,' ',ver,' -preview',switches ⍝ Ask what is now
      assert'No changes required'≡19↑z                                             ⍝ We should be back to 18.2
     
      z←⎕SE.UCMD CMD,' current -preview',switches ⍝ Ask what is now                ⍝ Check that "current" keyword works
      assert'No changes required'≡19↑z
     
      ⍝ --- Validate error message when trying to do -user=all and not an Admin
      :If ~IsUserAnAdmin
          z←⎕SE.UCMD CMD,' 18.2 -user=all -nobackup -qa_mode'
          assert 1∊' -user=current'⍷z
      :EndIf
     
     ⍝ --- Validate we can get rid of Directory associations
     ⍝     --- And change the default for source files to "Run" rather than "Edit"
      z←⎕SE.UCMD CMD,' 18.2 -dir=hide -source=run -nobackup',switches
     
      z←⎕SE.UCMD CMD,' details',switches
      assert~∨/1∊¨'Directory'∘⍷¨z[;1]  ⍝ No Directory entries
      assert'Run'≡⊃z[1⍳⍨1∊¨'dyalogfile\shell'∘⍷¨z[;1];2]                    ⍝ Default action is Run
      assert 1∊'dyalog.exe",0'⍷⊃z[1⍳⍨1∊¨'dyalogfile\DefaultIcon'∘⍷¨z[;1];2] ⍝ With suitable Icon
     
      ⎕CMD'reg import "',backup,'"'                                                ⍝ Restore the backup
      ⎕NDELETE backup
     
      r←'Tests passed'
    ∇

    :EndSection

:EndNamespace ⍝ EditFileAssociations  $Revision: 1774 $
