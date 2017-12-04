unit DeleteFilesU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Buttons, ComCtrls;

Type
  TRDMode = (rdNone, rdPrefix, rdAppend, rdRemove, rdReplace, rdDelete);
type
  TForm1 = class(TForm)
    StatusBar1: TStatusBar;
    Panel1: TPanel;
    edDeleteFiles: TMemo;
    Label1: TLabel;
    tpan: TSplitter;
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
    procedure DeleteOneFile;
    property sStatusBar: String write SetStatusBar;
    property sStatus: String  read GetStatus write SetStatus;
  end;

var
  Form1: TForm1;

implementation
Uses
  ShellAPI;
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
  btnDoIt.Enabled := True;
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
begin
  UpdateCaption;
  Timer1.Interval := StrToInt(Trim(edTimer.Text));
  iDeleteCount := 0;
  iErrorCount := 0;
  iFilesNotFoundCount := 0;
  iErr := 0;
  sError := '';
  edStatus.Clear;
  btnAbort.Enabled := True;
  btnDoIt.Enabled := False;
  dtStartTime := Now;
  Timer1.Enabled := True;
end;

procedure TForm1.cbxAppendToFilename1Click(Sender: TObject);
begin
  if rgMode.ItemIndex = -1 then
    exit;
  rdMode := TrdMode(Succ(rgMode.ItemIndex));
  edAppendToFIlename.EditLabel.Caption := csAppendToFilenameOriginal;
  // edAppendToFilename.Enabled := cbxAppendToFilename.Checked OR cbxPrePend.Checked OR cbxRemoveString.Checked;
  edReplaceWithFilename.Enabled := False;
  edAppendToFilename.Enabled := rdMode in [rdAppend, rdPrefix, rdRemove, rdReplace];
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

procedure TForm1.DeleteOneFile;
var
  sFile: String;
  sNewFile: String;
  sSuffix: String;
  sPath: String;
  p1: integer;
begin
  UpdateCaption;
  if edDeleteFiles.Lines.Count > 0 then
  begin
    sFile := edDeleteFiles.Lines.Strings[0];
    if FileExists(sFile) then
    begin
      sStatusBar := Format('FileExists: %s', [sFile]);
//      if cbxAppendToFilename.Checked OR cbxPrePend.Checked OR cbxRemoveString.Checked then
      if rdMode in [rdAppend, rdPrefix, rdRemove, rdReplace] then
      begin
        sSuffix := edAppendToFilename.Text;
        if Length(sSuffix)=0 then
        begin
          iErr := -1;
          sError := 'Append to Filename string is not assigned.';
          Abort;
        end;
        if FileExists(sFile) then
        begin
          sPath := ExtractFilePath(sFile);
          sNewFile := extractFileName(sFile);
          p1 := Pos('.', sNewFile);
          if (P1 > 0) OR (rdMode in [rdPrefix, rdRemove]) then // cbxPrePend.Checked OR cbxRemoveString.Checked then
          begin
            if rdMode = rdRemove then // cbxRemoveString.Checked then
            begin
              p1 := Pos(sSuffix, sNewFile);
              if p1>0 then
              begin
                Delete(sNewFile, p1, Length(sSuffix));
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
            end
            else
            if rdMode = rdAppend then // cbxAppendToFilename.Checked then
              Insert(sSuffix, sNewFile, p1)
            else
            if rdMode = rdReplace then
            begin
              p1 := Pos(edAppendToFilename.Text, sNewFile);
              if p1 > 0 then
              begin
                Delete( sNewFile, p1, Length(edAppendToFilename.Text));
                Insert(edReplaceWithFilename.Text, sNewFile, p1);
              end
              else
              begin
                sStatus := Format('File NOT renamed: %s ** String NOT Found.', [sFile]); // adds filename to status list
                sStatus := Format('     --> %s', [sNewFile]); // adds filename to status list
                Inc(iDeleteCount);
                //sStatus := sFile;
                edDeleteFiles.Lines.Delete(0);
              end;
            end
            else
              sNewFile := Format('%s%s', [sSuffix, sNewFile]);
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
      if rdMode = rdDelete then // cbxDeleteFile.Checked then
      begin
        if DeleteFile(sFile) then
        begin
          sStatus := Format('File deleted: %s', [sFile]); // adds filename to status list
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
end;
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
