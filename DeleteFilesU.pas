unit DeleteFilesU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, ComCtrls;

Type
  TRDMode = (rdNone, rdPrefix, rdAppend, rdRemove, rdReplace, rdRename, rdChangeFileTime, rdDelete);
type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    Panel1: TPanel;
    edDeleteFiles: TMemo;
    Label1: TLabel;
    Splitter: TSplitter;
    Panel2: TPanel;
    Label2: TLabel;
    edStatus: TMemo;
    btnDoIt: TBitBtn;
    btnAbort: TBitBtn;
    btnClose: TBitBtn;
    edTimer: TLabeledEdit;
    Timer1: TTimer;
    cbxStopOnError: TCheckBox;
    edAppendToFilename: TLabeledEdit;
    rgMode: TRadioGroup;
    edReplaceWithFilename: TLabeledEdit;
    procedure btnDoItClick(Sender: TObject);
    procedure btnAbortClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure WndProc(var Msg: TMessage); Override;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbxAppendToFilename1Click(Sender: TObject);
  private
    { Private declarations }
    procedure SetStatusBar(const S: String);
    procedure SetStatus(const S: String);
    function GetStatus: String;
    procedure UpdateCaption;

  public
    { Public declarations }
    iDeleteCount: Integer;
    iErrorCount: Integer;
    iFilesNotFoundCount: Integer;
    dtStartTime: TDateTime;
    dtEndTime: TDateTime;
    iErr: Integer;
    sError: String;
    bClosing: Boolean;
    rdMode: TrdMode;
    csAppendToFilenameOriginal: String;
    sIncSuffix: String;
    iIndex: Integer;
    bIncIndex: boolean;
    bIncIndexR: Boolean;
    sIncReplace: string;
    iIndexReplace: integer;
    procedure DeleteOneFile;
    property sStatusBar: String write SetStatusBar;
    property sStatus: String  read GetStatus write SetStatus;
  end;

var
  Form1: TForm1;

implementation
Uses
 DateUtils,  ShellAPI;
{$R *.dfm}

procedure TForm1.WndProc(var Msg: TMessage);
var wNum: Word;
    szBuff: Array[0..255] of Char;
    wN: Word;
    sFilename: String;
    //sExt: String;
    //Pt: TPoint;
begin
  if (Msg.Msg = WM_DropFiles) then
  begin
     Msg.Result := 0;
     wNum := DragQueryFile(Msg.wParam, $FFFFFFFF, nil, 0); //$FFFF, NIL, 0);
     if wNum =0 then
     Begin
       MessageDlg('Andy''s View can only accept one file for now', mtWarning, [mbOk],0);//ShowMessage(IntToStr(Num));
       wNum := 1;
     end;
     For wN := 0 to pred(wNum) do
     begin
         DragQueryFile(Msg.wParam, wN, @szbuff, pred(SizeOf(szbuff)));
{            DragQueryPoint(Msg.wParam, Pt);
         Canvas.TextOut(Pt.X, Pt.Y, StrPas(Buff));}
{  Originally I was just displaying the single file at specified location }
           sFilename := StrPas(szbuff);
           edDeleteFiles.Lines.Add(sFilename);
           //sDroppedFile := sFilename;
           // ProcessFile(sDroppedFile);
           //Memo1.Lines.Add(sFilename);
     end;
     DragFinish(Msg.wParam);
  end
  else
    inherited WndProc(Msg);
  if (NOT bClosing) AND Assigned(edDeleteFiles) then
    UpdateCaption;
end;

procedure TForm1.SetStatusBar(const S: string);
begin
  StatusBar1.SimpleText := S;
  Application.ProcessMessages;
end;

procedure TForm1.SetStatus(const S: string);
begin
  edStatus.Lines.Add(S);
  StatusBar1.SimpleText := S;
  Application.ProcessMessages;
end;

function TForm1.GetStatus: String;
begin
  Application.ProcessMessages;
  result := StatusBar1.SimpleText;
end;

procedure TForm1.btnAbortClick(Sender: TObject);
var
  sMsg: String;
begin
  Timer1.Enabled := False;
  btnDoIt.Enabled := False;
  btnAbort.Enabled := False;
  dtEndTime := Now;
  UpdateCaption;
  sStatus := #32;
  sStatus := Format('StartTime: %s', [DateTimeToStr(dtStartTime)]);
  sStatus := Format('EndTime: %s', [DateTimeToStr(dtEndTime)]);
  sStatus := #32;
  sStatus := Format('Files total: %d', [iDeleteCount+iErrorCount+iFilesNotFoundCount]);
  sStatus := Format('Files not found: %d', [iFilesNotFoundCount]);
  sStatus := Format('Errors: %d', [iErrorCount]);
  if rdMode = rdDelete then // cbxDeleteFile.Checked then
    sMsg := 'Files deleted:'
  else
    sMsg := 'Files found:';
  sStatus := Format('%s %d', [sMsg, iDeleteCount]);
  sStatusBar := Format('%s %d Errors: %d Files not found: %d', [sMsg, iDeleteCount, iErrorCount, iFilesNotFoundCount]);
end;

procedure TForm1.UpdateCaption;
begin
  // if Assigned(cbxAppendToFilename) AND (cbxAppendToFilename.Checked) then
  if rdMode = rdAppend then
    Label1.Caption := Format('Copying Files: [%d]', [edDeleteFiles.Lines.Count]);
  // if Assigned(cbxDeleteFile) AND (NOT cbxDeleteFile.Checked) then
  if rdMode <> rdDelete then
    Label1.Caption := Format('Check Files Exist: [%d]', [edDeleteFiles.Lines.Count])
  else
     Label1.Caption := Format('Delete Files: [%d]', [edDeleteFiles.Lines.Count]);
end;

procedure TForm1.btnDoItClick(Sender: TObject);
var
  lstTemp: TStringList;
begin
  UpdateCaption;
  Timer1.Interval := StrToInt(Trim(edTimer.Text));
  iDeleteCount := 0;
  iErrorCount := 0;
  iFilesNotFoundCount := 0;
  iErr := 0;
  sError := '';
  sIncSuffix := '';
  iIndex := 0;
  bIncIndex := False;
  bIncIndexR := False;
  sIncReplace := '';
  iIndexReplace := 0;
  edStatus.Clear;
  btnAbort.Enabled := True;
  btnDoIt.Enabled := False;

  lstTemp := TStringList.Create;
  lstTemp.Assign(edDeleteFiles.Lines);
  lstTemp.Sort;
  edDeleteFiles.Lines.Assign(lstTemp);
  FreeAndNil(lstTemp);

  dtStartTime := Now;
  Timer1.Enabled := True;
end;

procedure TForm1.cbxAppendToFilename1Click(Sender: TObject);
var
  sTemp: String;
begin
  if rgMode.ItemIndex = -1 then
    exit;
  rdMode := TrdMode(Succ(rgMode.ItemIndex));
  edAppendToFIlename.EditLabel.Caption := csAppendToFilenameOriginal;
  // edAppendToFilename.Enabled := cbxAppendToFilename.Checked OR cbxPrePend.Checked OR cbxRemoveString.Checked;
  edReplaceWithFilename.Enabled := False;
  edAppendToFilename.Enabled := rdMode in [rdAppend, rdPrefix, rdRemove, rdReplace, rdRename, rdChangeFileTime];
  case rdMode of
    rdNone: sTemp := csAppendToFIlenameOriginal;
    rdPrefix: sTemp := 'Prefix filename:';
    rdAppend: sTemp := 'Append filename:';
    rdRemove: sTemp := 'Remove filename:';
    rdReplace: sTemp := 'Find filename:';
    rdRename: sTemp := 'Rename files:';
    rdChangeFileTime: sTemp := 'Change file DateTime:';
    rdDelete: sTemp := 'DELETING ALL FILES';
  end;
  edAppendToFilename.EditLabel.Caption := sTemp;
  btnDoIt.Enabled := True;
  btnAbort.Enabled := True;
  if rdMode = rdReplace then
  begin
    edAppendToFilename.EditLabel.Caption := 'Find String';
    edReplaceWithFilename.Enabled := True;
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;

  DeleteOneFile;
  Timer1.Interval := StrToInt(Trim(edTimer.Text));
  if (edDeleteFiles.Lines.Count > 0)
    AND ((iErr = 0) OR ((iErr>0) AND (NOT cbxStopOnError.Checked)))
      then
        Timer1.Enabled := True
  else
    btnAbortClick(Self);
  if NOT Timer1.Enabled  then
  begin
    rgMode.ItemIndex := -1;
    rdMode := rdNone;
  end;
end;

// http://www.delphigroups.info/2/0f/484890.html
const
  // 24 * 60 * 60 * 1000 * 1000 * 10;
  CentiMicroSecondsPerDay = 864000000000.0;
  FileTimeStart = -109205;  // 1601-01-01T00:00:00
function DateTimeToLocalFileTime(Value: TDateTime): TFileTime;
begin
  Int64(Result) := Round((Value - FileTimeStart) *
                   CentiMicroSecondsPerDay);
end;
function LocalFileTimeToDateTime(Value: TFileTime): TDateTime;
begin
  Result := (Int64(Value) / CentiMicroSecondsPerDay) + FileTimeStart;
end;
const
  FILE_WRITE_ATTRIBUTES = $0100;
procedure SetFileCreationTime(const FileName: string; const DateTime: TDateTime);
var
  Handle: THandle;
  FileTime: TFileTime;
  LocalFileTime: TFileTime;
  Result: Boolean;
begin
  Handle := CreateFile(PChar(FileName), FILE_WRITE_ATTRIBUTES,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL, 0);
  if Handle=INVALID_HANDLE_VALUE then
    RaiseLastOSError;
  try
    LocalFileTime := DateTimeToLocalFileTime(DateTime);
    Result := LocalFileTimeToFileTime(LocalFileTime, FileTime);
    if Result then
    Begin
      if not SetFileTime(Handle, @FileTime, @FileTime, @FileTime) then
        RaiseLastOSError;
    End
    else
      RaiseLastOSError;
  finally
    CloseHandle(Handle);
  end;
end;

procedure TForm1.DeleteOneFile;
var
  sFile: String;
  sNewFile: String;
  sSuffix: String;
  sReplaceText: String;
  sTemp: String;
  sPath: String;
  sIndex: String;
  p1, p2: integer;
  dtNewDateTime: TDateTime;
procedure ModeRemove;
begin
  p1 := Pos(sSuffix, sNewFile);
  if bIncIndex then
    p1 := Pos(sIncSuffix, sNewFile);
  if p1>0 then
  begin
    if NOT bIncIndex then
      Delete(sNewFile, p1, Length(sSuffix))
    else
      Delete(sNewFile, p1, Length(sIncSuffix));
  end
  else
  begin
    iErr := GetLastError;
    Inc(iErrorCount);
    sError := Format('Error String not in File: [%d] %s', [iErr, SysErrorMessage(iErr)]);
    sStatus := sError;
    sStatus := Format('     %s', [sFile]); // adds filename to status list
    edDeleteFiles.Lines.Delete(0);
  end;
end; // procedure ModeRemove

procedure ModeAppend;
begin
  if NOT bIncIndex then
    Insert(sSuffix, sNewFile, p1)
  else
    Insert(sIncSuffix, sNewFile, p1);
end; // procedure ModeAppend;

// sets sNewFile
procedure ModeReplace;
begin
  if NOT bIncIndex then
    p1 := Pos(edAppendToFilename.Text, sNewFile)
  else
    p1 := Pos(sIncSuffix, sNewFile);
  if p1 > 0 then
  begin
    if NOT bIncIndex then
      Delete( sNewFile, p1, Length(sSuffix))
    else
      Delete( sNewFile, p1, Length(sIncSuffix));

    if NOT bIncIndexR then
      Insert(edReplaceWithFilename.Text, sNewFile, p1)
    else
      Insert(sIncReplace, sNewFile, p1);
  end
  else
  begin
    sStatus := Format('File NOT renamed: %s ** String NOT Found.', [sFile]); // adds filename to status list
    sStatus := Format('     --> %s', [sNewFile]); // adds filename to status list
    Inc(iDeleteCount);
    //sStatus := sFile;
    edDeleteFiles.Lines.Delete(0);
  end;
end; // procedure ModeReplace

// sets sNewFile
procedure ModeRename;
begin
  if NOT bIncIndex then
    sNewFile := sSuffix
  else
    sNewFIle := sIncSuffix;
end; // ModeRename

procedure DoIncrement(sTest: String; var bIndex: Boolean; var iIndex: Integer; var sTestIncremented: String);
begin
	if Length(sTest)=0 then
	begin
	  iErr := -1;
	  sError := 'Append to Filename string is not assigned.';
	  Abort;
	end;
	// suffix or prefix
	p1 := Pos('<', sTest);
	p2 := Pos('>', sTest);
	if (p1>0) AND (p2>0) then
	//if (NOT bIncIndex) AND (p1>0) AND (p2>0) then
	begin
	  sIndex := Copy(sTest, Succ(p1), (Pred(p2)-p1));
	  if NOT bIncIndex then
		iIndex := StrToInt(sIndex)
	  else
		Inc(iIndex);
	  bIncIndex := True;
	  sTestIncremented := sTest;
	  Delete(sTestIncremented, p1, (p2-Pred(p1)));

	  // There is always better way:
	  //  Result := Format('%.*d', [len,value]);

	  // or      00-<01> Intro by Teachers
	  //    Result := Format('%.'+IntToStr(len)+'d', [value]);

	  sTemp := '%.'+IntToStr(Length(sIndex))+'d';
	  sTemp := Format(sTemp, [iIndex]);
	  Insert(sTemp, sTestIncremented, p1);
	end;
end; // DoIncrement

begin // procedure TForm1.DeleteOneFile;
  UpdateCaption;
  if edDeleteFiles.Lines.Count > 0 then
  begin
    sFile := edDeleteFiles.Lines.Strings[0];
    if FileExists(sFile) then
    begin
      sStatusBar := Format('FileExists: %s', [sFile]);

      if rdMode in [rdAppend, rdPrefix, rdRemove, rdReplace, rdRename] then
      begin
        sSuffix := edAppendToFilename.Text;
        // suffix or prefix
        // does the suffix get incremented?
        DoIncrement(sSuffix, bIncIndex, iIndex, sIncSuffix);
        // ************
        // replace text
        // ************
        sReplaceText := edReplaceWithFilename.text;
        if Length(sReplaceText)>0 then
          DoIncrement(sReplaceText, bIncIndexR, iIndexReplace, sIncReplace);
        if FileExists(sFile) then
        begin
          sPath := ExtractFilePath(sFile);
          sNewFile := extractFileName(sFile);
          // p1 is for end of file for Append...
          p1 := Pos('.', sNewFile);
          if P1 = 0 then
            p1 := Length(sNewFile);
          // p1 is for Append string to file
          if (P1 > 0) OR (rdMode in [rdPrefix, rdRemove]) then // cbxPrePend.Checked OR cbxRemoveString.Checked then
          begin
            if rdMode = rdRemove then // cbxRemoveString.Checked then
            begin
              // Sets sNewFile
              ModeRemove;
            end
            else
            if rdMode = rdAppend then // cbxAppendToFilename.Checked then
            begin
              // sets sNewFile
              ModeAppend;
            end
            else
            if rdMode = rdReplace then
            begin
              // sets sNewFile
              ModeReplace;
            end
            else
            if rdMode = rdRename then
            begin
              // sets sNewFile
              ModeRename;
            end
            else
            begin // must be rdPrefix
              if NOT bIncIndex then
                sNewFile := Format('%s%s', [sSuffix, sNewFile])
              else
                sNewFIle := Format('%s%s', [sIncSuffix, sNewFile]);
            end;
            sNewFile := Format('%s%s', [sPath, sNewFile]);
            if NOT FileExists(sNewFile) then
            begin
              if RenameFile(sFile, sNewFile) then
              begin
                sStatus := Format('File renamed: %s', [sFile]); // adds filename to status list
                sStatus := Format('     --> %s', [sNewFile]); // adds filename to status list
                Inc(iDeleteCount);
                //sStatus := sFile;
                edDeleteFiles.Lines.Delete(0);
              end
              else
              begin
                iErr := GetLastError;
                Inc(iErrorCount);
                sError := Format('Error with Renameing New File: [%d] %s', [iErr, SysErrorMessage(iErr)]);
                sStatus := sError;
                sStatus := Format('     %s', [sFile]); // adds filename to status list
                edDeleteFiles.Lines.Delete(0);
              end;
            end
            else
            begin
              iErr := GetLastError;
              Inc(iErrorCount);
              sError := Format('Error with New File: [%d] %s', [iErr, SysErrorMessage(iErr)]);
              sStatus := sError;
              sStatus := Format('     %s', [sFile]); // adds filename to status list
              edDeleteFiles.Lines.Delete(0);
            end;
          end
          else
          begin
            iErr := GetLastError;
            Inc(iErrorCount);
            sError := Format('Error connot identify extention ".": [%d] %s', [iErr, SysErrorMessage(iErr)]);
            sStatus := sError;
            sStatus := Format('     %s', [sFile]); // adds filename to status list
            edDeleteFiles.Lines.Delete(0);
          end;
        end
        else
        begin
          iErr := GetLastError;
          Inc(iErrorCount);
          sError := Format('File does not exist: [%d] %s', [iErr, SysErrorMessage(iErr)]);
          sStatus := sError;
          sStatus := Format('     %s', [sFile]); // adds filename to status list
          edDeleteFiles.Lines.Delete(0);
        end;
      end
      else
      if rdMode = rdChangeFileTime then
      begin
        sSuffix := edAppendToFilename.Text;
        DoIncrement(sSuffix, bIncIndex, iIndex, sIncSuffix);
        if Length(sIncSuffix)>0 then
          sSuffix := sIncSuffix;
        dtNewDateTime := StrToDateTime(sSuffix); //edAppendToFilename.Text);
        try
          SetFileCreationTime(sFile, (dtNewDateTime));
          except on E: Exception do
          begin
            iErr := GetLastError;
            Inc(iErrorCount);
            sError := Format('Exception: [%d] %s', [iErr, E.Message]);
            sStatus := sError;
            sStatus := Format('     %s', [sFile]); // adds filename to status list'
          end;
        end;
        sStatus := Format('File time changed [%s]: %s', [DateTimeToStr(dtNewDateTime), sFile]); // adds filename to status list
        edDeleteFiles.Lines.Delete(0);
        Inc(iDeleteCount);
      end
      else
      if rdMode = rdDelete then // cbxDeleteFile.Checked then
      begin
        if DeleteFile(sFile) then
        begin
          Inc(iDeleteCount);
          //sStatus := sFile;
          edDeleteFiles.Lines.Delete(0);
        end
        else
        begin
          iErr := GetLastError;
          Inc(iErrorCount);
          sError := Format('Error deleting file: [%d] %s', [iErr, SysErrorMessage(iErr)]);
          sStatus := sError;
          sStatus := Format('     %s', [sFile]); // adds filename to status list
          edDeleteFiles.Lines.Delete(0);
        end;
      end // if cbxDeleteFile then
      else
      begin
          sStatus := sFile;
          Inc(iDeleteCount);
          edDeleteFiles.Lines.Delete(0);
      end;
    end
    else
    begin
      sStatus := Format('*Cannot find file: %s', [sFile]);
      edDeleteFiles.Lines.Delete(0);
      Inc(iFilesNotFoundCount);
    end;
  end;
end; // procedure TForm1.DeleteOneFile;

procedure TForm1.FormCreate(Sender: TObject);
begin
  DragAcceptFiles(Handle, True);
  csAppendToFilenameOriginal := edAppendToFilename.EditLabel.Caption;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  bClosing := True;
  DragAcceptFiles(Handle, False);
end;

end.
