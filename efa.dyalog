:Namespace efa ⍝ V3.02
⍝ Changes the associations of .dws, .dyapp, .apl? and .dyalog files
⍝
⍝ 2022 01 21 MKrom: Fix #7 Classic 32 displays as Unicode 32 in GUI
⍝ 2022 01 20 MKrom: Complete rewrite for v18.2

⍝∇:require =\WinReg.dyalog


    ⎕ml←⎕io←1
    DESC←'Set Windows File Associations for directories and files used by Dyalog APL'
    CMD←' '~⍨NAME←'fileassociations'
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
    ExistingRegs←{⍵/⍨##.WinReg.DoesKeyExist¨⍵}     ⍝ Filter list of registry keys
    Hex←{'0123456789abcdef'[1+⍵]}

      VersionIDs←{                                ⍝ nn.n[Ubb] format from APL version name
          vers←GetVersion¨⍵
          tail←'CU'[1+1∊¨'Unicode'∘⍷¨⍵]
          tail,¨←'32' '64'[1+1∊¨'-64'∘⍷¨⍵]
          vers,¨(~tail∊⊂'U64')/¨'-',¨tail
      }

    :Section UCMD

    ∇ r←List;parse
      r←⎕NS''
      parse←'1S -preview -user=current all -dir=show hide'
      parse,←'-workspace=run load -dyapp=run edit -script=run edit'
      parse,←'-config=edit run -source=edit run '
      parse,←'-confirm -nobackup -qa_mode'
     
      r.(Name Desc Group Parse)←CMD DESC'MSWIN'parse
      r/⍨←⎕SE.SALTUtils.WIN
    ∇

    ∇ r←level Help Cmd
      r←⊂DESC
      r,←⊂'    ]',Cmd,' version|status|details|remove|backup -preview -dir=show|hide'
      r,←⊂'                 -workspace=run|load script=run|edit -dyapp=run|edit '
      r,←⊂'                 -source=edit|run|load -config=edit|run'
      r,←⊂'                 -user=current|all'
          
      →(level=0)⍴0
     
      r,←⊂''
      r,←⊂'    ∘  Set Windows "file associations" for Dyalog APL, to add right-click menu items'
      r,←'       and double-click actions in Windows Explorer.' ''
      r,←⊂'    ∘  <version> is the version to set associations for.'
      r,←⊂'    ∘  If no version number or action is specified, a GUI will pop up to offer options.'
      r,←'' '    ∘  Supported actions:'
      r,←⊂'         status     Returns a brief overview of current associations.'
      r,←⊂'         details    Returns a full list of current registry settings.'
      r,←⊂'         remove     Removes all current settings.'
      r,←⊂'         backup     Takes a backup of the current registry settings in the form of a registry file.'
      r,←⊂'                    (all operations which make changes will take a backup unless -nobackup is set)'
     
      r,←'' '    ∘ Supported switches (first option is the default):' ''
      r,←⊂'         -preview                   display required changes but do not apply them'
      r,←⊂'         -dir       =show|hide      show or hide actions for directories (v18.2 or later only)'
      r,←⊂'         -config    =edit|run       set default action for config files (.dcfg)'
      r,←⊂'         -source    =edit|run|load  set default action for source files (.apl? except .apls)'
      r,←⊂'         -workspace =run|load       set default action for workspaces'
      r,←⊂'         -script    =run|edit       set default action for script files (.apls)'
      r,←⊂'         -dyapp     =run|edit       set default action for (deprecated) dyappp files'
      r,←⊂'         -user      =current|all    decide whether to work on HKEY_CURRENT_USER or HKEY_LOCAL_MACHINE'
      r,←⊂'                                    (defaults to -user=all unless HKCU contains settings for the current user)'
      r,←⊂'         -nobackup                  do NOT take a backup before performing the operation'
      r,←⊂'         -confirm                   display changes and ask for confirmation before applying them'
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
          t,←('If you select No but wish to perform the operation for the current user, include "-user=current" on the ',CMD,' command line.') ''
          :If ~Args.qa_mode
          :AndIf 'Adminstrative privileges required for -user=all'MsgBoxYN t
               Args.SwD[Args.SwD[;1]⍳⊂'user';2]←⊂'all'
              →0⊣rc←LaunchAdminProcess GenUCMD Args
          :EndIf                      
          Args.SwD[Args.SwD[;1]⍳⊂'user';2]←⊂'current'
          →0⊣rc←↑'Aborted. Try:' '' ('      ]',GenUCMD Args)
      :EndIf
     
      :If Args._1≡'DETAILS'
          :If 0=≢rc←⍕¨Show 1
              rc←'No Dyalog file associations found in ',REG
          :EndIf
          →0
      :EndIf
     
      ivers←InstalledVersions        ⍝ A vector of all installed versions of Dyalog APL (handles 11.0 onward)
      g←⍒vers←VersionIDs ivers       ⍝ nn.n[-Ubb] format
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
              ⎕←↑'Processing:' '' ('      ]',GenUCMD Args)  
              →RESTART
          :EndIf
      :EndIf
     
      validcmd←(⊂Args._1)∊'STATUS' 'DETAILS' 'REMOVE' 'BACKUP'
      validvers←(⊂Args._1)∊vers
     
      :If (Args._1≡'STATUS')∨~validcmd∨validvers
          rc←(Args._1≢'STATUS')/('*** Invalid version: ',(⍕Args._1),' ***')''
          rc,←({'Status for ',(1 ⎕C ⍵),' user',((⍵≡'all')/'s'),':'}Args.user) ''
          rc,←'Installed versions are:' ''(⍕'' '',vers)''
          rc,←CurrentAssociations 1                  
          rc,←'' 'To change associations, or repair associations for the current version, enter e.g.' ''
          rc,←⊂'      ]',CMD,' ',⊃vers
          rc←↑rc
     
      :ElseIf Args._1≡'REMOVE'
          keys←1 ReadReg REG      ⍝ Find existing keys
          rc←Args DeleteReg keys
     
      :ElseIf Args._1≡'BACKUP'
          rc←Backup Args
     
      :Else
          vernum←⊃2⊃⎕VFI{(¯1+⍵⍳'-')↑⍵}Args._1
          path←(vers⍳⊂Args._1)⊃ipaths,⊂'C:\Program Files\Dyalog\APL v.',Args._1,'\not installed\'
     
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
      cmd,←⊂'LX="⎕←↑⍪'''' ''Administrative process started. Now re-run:'' '''' ''      ]',ucmd,'''"'
      psi←⎕NEW Diagnostics.ProcessStartInfo(1↑cmd)
      psi.Arguments←⍕1↓cmd
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

    ∇ r←CurrentAssociations fmt;keys;labels;i;m;n
      ⍝ Report on existing associations found in the registry
     
      ⍝ Set up a list of keys representing different kinds of association
     
      keys←PreviewSource PreviewWS,¨⊂'\LocalServer32'
      labels←'Workspace Preview' 'Source Preview'
      keys,←,FileTypes∘.,'file\shell\Run\command' 'file\shell\Edit\command'
      labels,←2/FileTypes
      keys,←⊂(⊃DirKeys),'\shell\DyalogLoad\command'
      labels,←⊂'Directories'
     
      r←Show 0                 ⍝ read all the keys
      i←(1∊¨keys∘.⍷r[;1])⍳⍤1⊢1 ⍝ search for "our" keys
      m←i≤≢r
      r←(m/labels),r[m/i;,2]   ⍝ keys and values of interest
      r←(1∊¨'Dyalog APL'∘⍷¨r[;2])⌿r
      r[;2]←VersionIDs r[;2]   ⍝ convert folder names to nn.n[-Ubb] format
      r←r[r[;1]⍳∪r[;1];]       ⍝ remove duplicates
     
      →fmt↓0
     
      :Select ≢∪r[;2]            ⍝ all associated with same version (normal)
      :Case 0
          r←,⊂'No current associations defined.'
      :Case 1
          r←,⊂'Current assocation: ',⊃r[1;2]
      :Else                    ⍝ list individual associations
          r←'Current associations:' '',⍕¨↓(⊂'   '),r
      :EndSelect
    ∇

    ∇ (msg str bin del)←BuildReg(path vernum REG opts);types;str;bin;mask;Text;dws;dyapp;dyalog;Icon1;script;pv;clsid;dn;type;extns;name;key;icons;values;default;subkeys;delete;todelete;i;labels;dir;EditCmd;PreviewCmd;RunCmd;RunShCmd;LoadCmd;DyalogIcon;EditorIcon;actionicons;subs;cmds;editcmd;loadcmd;runcmdEditWithNotepad;ft;pvnum;pvpath;versions;Version;ver;shell;RunDyappCmd
    ⍝ Builds data to be written to registry
     
      str←bin←0 2⍴'' ⍝ String and Binary values to set
      del←⍬          ⍝ Keys to be deleted
      msg←''         ⍝ Empty if OK, else error message
     
      EditWithNotepad←'notepad "%1"'
     
      RunCmd←'"',path,'dyalog.exe" LOAD="%1"'
      RunDyappCmd←'"',path,'dyalog.exe" DYAPP="%1"'
      RunShCmd←'powershell -File "',path,'Samples\scripts\bin\dyalogscript.ps1" "%1" %*'
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
          v←GetVersion¨0 1↓m⌿update
          (m/m)←(v[;1]∊Args.vers)∧>/⍋⍤1⊢v ⍝ Entries which would "downgrade" the previewer
          update←(~m)⌿update
      :EndIf
     
      :If 0∧.=≢¨remove add update
          →0⊣rc←'No changes required to registry to use ',Args._1
      :EndIf
      →(0≠⍴rc←ConfirmRegChanges add remove update Args)⍴0
    ∇

    ∇ file←Backup Args;keys;txt;file;del;hdr
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
              ⎕←⎕DM
              ⎕←'Failed to set: ',key,' rc=',⍕t
              ∘∘∘
          :EndTrap
      :EndFor
    ∇

    :Section GUI

    ∇ (ok Args)←SelectGui(vers curr Args);Text;Y;X;vers;size;listx;neither;line1;i;type;dws;dyapp;dyalog;Applications;f;z;list;ok;users;selected;done;cap
    ⍝ Creates GUI
     
      Text←(FmtCurrent curr),'' 'Select version to associate:'
      cap←'Set File Associations for Dyalog APL'
      list←FmtVersions vers  
      (vers list)←(⊂⍒list)∘⌷¨vers list
      listx←300⌊19×⍴vers
      size←(308+listx),365
     
      'f'⎕WC'Form' cap('Size'size)('Coord' 'Pixel')('Sizeable' 0)('MaxButton' 0)('MinButton' 0)
      'f.fnt'⎕WC ⎕SE.SALTUtils.Fonts.Message
      'f.fnt'⎕WS'Size' 16
      'f'⎕WS'Event'('Close' 1)
      'f'⎕WS'FontObj' 'f.fnt'
      'f.msg'⎕WC'Text'(↑Text)(15 15)
      'f.list'⎕WC'List'('Items'list)('Posn'(165 30))('Size'(listx,300))('Selitems'(vers∊2↓curr[;2]))('Event' 'MouseDblClick' 1)
     
      'f.dir'⎕WC'Button' '&Show Windows Explorer context menu items for directories'((180+listx),15)('Style' 'Check')('State' (Args.dir≡'show'))    
      'f.backup'⎕WC'Button' '&Create a backup of the relevant registry settings'((205+listx),15)('Style' 'Check')('State' (~Args.nobackup))
      users←'Current User' ('All users ',(~IsUserAnAdmin)/' (requires admin rights)')
      
      'f.userlabel' ⎕WC 'Text' 'Set associations for:' ((232+listx),15)
      'f.user'⎕WC'Combo'('Items' users)('SelItems'((Args.user≡'all')⌽1 0))('Posn' ((230+listx),125))('Size' 30 200)
     
      'f.bapply'⎕WC'Button'('Caption' '&Apply')('Posn'((1⊃size)-40)100)('Size' 30 70)('Event' 'Select' 1)
      'f.bcancel'⎕WC'Button'('Caption' '&Cancel')('Posn'((1⊃size)-40)200)('Size' 30 70)('Event' 'Select' 1)
     
      ⎕NQ'f.bcancel' 'Gotfocus'
      :Repeat
        z←⎕DQ'f'
        ok←(⊂2↑z)∊('f.bapply' 'Select')('f.list' 'MouseDblClick')
        ok←ok∧1=+/f.list.SelItems
        :If ~done←ok∨'f.bcancel'≡⊃z
            cap MsgBoxAlert 'You must select a version!'
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
      r←r,¨' ',¨(5⍴'Unicode 64' 'Classic 64' 'Unicode 32' 'Classic 32')['U64' 'C64' 'U32' 'C32'⍳p↓¨vers]
    ∇

    ∇ Text←FmtCurrent curr;dws;dyapp;dyalog;script;dir;pv;i
      i←curr[;1]⍳'dws' 'dyapp' 'dyalog' 'dyalogscript' 'Directories' 'Source Preview'
      (dws dyapp dyalog script dir pv)←(curr[;2],⊂'(none)')[i]
     
      Text←⊂'Current associations:'
      Text,←⊂'      Scripts             (.apls)                    ',script
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
      'Tests require a fresh installation'⎕SIGNAL('No changes required'≢19↑z)/11
     
      ivers←InstalledVersions
      'Version 18.0 needs to be installed'⎕SIGNAL((⊂'18.0')∊ivers)/11
     
      ⍝ --- Validate v18.2 Associations
      assoc←CurrentAssociations 0
      assert 8=≢assoc
      pv←(assoc[;1]⍳⊂'Workspace Preview')⊃assoc[;2]
      assert∧/((assoc[;1]∊'dcfg' 'dws' 'dyalog' 'dyapp' 'dyalogscript' 'Directories')/assoc[;2])∊⊂'18.2' ⍝ Most associations gone
     
      ⍝ --- Take a backup, switch to and verify 18.0, and finally restore to 18.2 using the backup
     
      backup←⎕SE.UCMD CMD,' backup',switches
     
      z←⎕SE.UCMD CMD,' 18.0 -nobackup',switches ⍝ Switch to v18.0 and validate the resulting associations
     
      assoc←CurrentAssociations 0
      assert 6=≢assoc
      assert∧/((assoc[;1]∊'dcfg' 'dws' 'dyalog' 'dyapp')/assoc[;2])∊⊂'18.0'        ⍝ Core associations switched
      assert∧/((assoc[;1]∊'Workspace Preview' 'Source Preview')/assoc[;2])∊⊂pv     ⍝ Preview should still use latest
      assert~∨/('dyalogscript' 'Directories')∊assoc[;1]                            ⍝ 18.0 has no script support
     
      ⎕CMD'reg import "',backup,'"'                                                ⍝ Restore the backup
      z←⎕SE.UCMD CMD,' ',ver,' -preview',switches ⍝ Ask what is now
      assert'No changes required'≡19↑z                                             ⍝ We should be back to 18.2
     
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

:EndNamespace ⍝ EditFileAssociations  $Revision: 1746 $
