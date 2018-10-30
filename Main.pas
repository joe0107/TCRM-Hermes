unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms, Dialogs, DB, ADODB, ExtCtrls, StdCtrls,
  JcThreadTimer, dxGDIPlusClasses, ComCtrls, IdUDPClient, IniFiles, JcVersionInfo, Menus, RzTray, IdBaseComponent,
  IdComponent, IdTCPConnection, IdTCPClient, DateUtils;

type
  TfmMain = class(TForm)
    ListBox1: TListBox;
    pnl1: TPanel;
    TcrmConn: TADOConnection;
    qrChangLog: TADOQuery;
    JcThreadTimer1: TJcThreadTimer;
    ProgressBar1: TProgressBar;
    Edit_Host: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Edit_Port: TEdit;
    Label3: TLabel;
    ListBox_Monitor: TListBox;
    bvl1: TBevel;
    Label4: TLabel;
    Edit_SQL: TEdit;
    JcVersionInfo1: TJcVersionInfo;
    RzTrayIcon1: TRzTrayIcon;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    IdTCPClient_Phone: TIdTCPClient;
    procedure FormCreate(Sender: TObject);
    procedure JcThreadTimer1Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure N1Click(Sender: TObject);
  private
    FLastLogID: array of Int64;
    FUDPClient: TIdUDPClient;
    FCommKind: string;

    procedure WriteLog(AMsg: string);
    function  GetLastLogID: Int64;
    procedure GetChangLogs(ATableNdx: Integer);
    function  GetMsg_ChangLog: string;
    procedure SendNotify_ChangLog(ATableNdx: Integer);
    procedure SendNotify(AMsg: string);
  private
    procedure RestoreConfig;
    procedure StoreConfig;
    procedure SetAdoConnection(AServer: string);
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;

implementation

{$R *.dfm}

procedure TfmMain.FormCreate(Sender: TObject);
var
  i, j: Integer;
begin
  JcVersionInfo1.FileName := Application.ExeName;
  Self.Caption := Format('TCRM 訊息發送中心 v %s', [JcVersionInfo1.FileVersion]);
  
  RestoreConfig;
  SetLength(FLastLogID, ListBox_Monitor.Count);
  j := GetLastLogID;

  for i := 0 to ListBox_Monitor.Count-1 do
    FLastLogID[i] := j;
    
  FUDPClient := TIdUDPClient.Create(Self);
  FUDPClient.Active := True;

  JcThreadTimer1.Enabled := True;
end;

function TfmMain.GetLastLogID: Int64;
begin
  with qrChangLog do
  begin
    if Active then Close;
    SQL.Clear;
    SQL.Add('SELECT MAX(REC_ID) AS MAX_ID FROM SYNC_LOG');
    Open;

    if not IsEmpty then
      Result := FieldByName('MAX_ID').AsInteger
    else
      Result := 0;

    Close;
  end;
  WriteLog(Format('Max Log ID = %d', [Result]));
end;

procedure TfmMain.WriteLog(AMsg: string);
begin
  with ListBox1 do
  begin
    Items.Add(Format('%s %s', [DateTimeToStr(Now), AMsg]));

    if Count > 500 then
      Items.Delete(0);

    ItemIndex := Count - 1;
  end;
end;

procedure TfmMain.JcThreadTimer1Timer(Sender: TObject);
var
  i: Integer;
begin
  with JcThreadTimer1 do
  begin
    Enabled := False;
    ProgressBar1.StepIt;
    //Self.Update;

    try
      for i := 0 to ListBox_Monitor.Count-1 do
      begin
        GetChangLogs(i);
        SendNotify_ChangLog(i);
      end;
    finally
      Enabled := True;
    end;
  end;
end;

procedure TfmMain.GetChangLogs(ATableNdx: Integer);
var
  aTableName: string;
begin
  aTableName := UpperCase(ListBox_Monitor.Items[ATableNdx]);

  with qrChangLog do
  begin
    if Active then Close;
    SQL.Clear;

    if (aTableName = 'WICSIPHE') then
    begin
      SQL.Add('SELECT TOP 100 REC_ID, TABLE_NAME, OP, EXTRA, IPHE004');
      SQL.Add('FROM SYNC_LOG A WITH(NOLOCK)');
      SQL.Add('LEFT JOIN WICSIPHE B WITH(NOLOCK) ON B.GUID = A.PK AND IPHE004 > GETDATE()-10');
    end
    else
    begin
      SQL.Add('SELECT TOP 100 REC_ID, TABLE_NAME, OP, EXTRA');
      SQL.Add('FROM SYNC_LOG WITH(NOLOCK)');
    end;

    SQL.Add('WHERE TABLE_NAME = :TABLE_NAME');
    SQL.Add('AND REC_ID > :REC_ID');
    //SQL.Add('AND EXPIRE = 0');
    SQL.Add('ORDER BY REC_ID');
    Parameters.ParamValues['TABLE_NAME'] := aTableName;
    Parameters.ParamValues['REC_ID'] := FLastLogID[ATableNdx];
    Open;

    if RecordCount > 0 then
    begin
      WriteLog(Format('[%s] Last ID = %d, Change Count = %d', [aTableName, FLastLogID[ATableNdx], RecordCount]));
    end;
  end;
end;

procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  StoreConfig;
  
  if Assigned(FUDPClient) then
  begin
    FUDPClient.Active := False;
    FUDPClient.Free;
  end;
end;

procedure TfmMain.SendNotify(AMsg: string);
begin
  if (FCommKind = 'UDP') then
  begin
    //FUDPClient.Send('10.1.1.212', 9311, AMsg);
    FUDPClient.Send(Edit_Host.Text, StrToIntDef(Edit_Port.Text, 9311), AMsg);
  end
  else if (FCommKind = 'TCP') then
  begin
    with IdTCPClient_Phone do
    begin
      try
        if not Connected then
        begin
          ConnectTimeout := 3000;
          Connect;
        end;
        SendCmd('PHONEDATA ' + AMsg);
      except
        IdTCPClient_Phone.Disconnect;
      end;
    end;
  end;
end;

procedure TfmMain.SendNotify_ChangLog(ATableNdx: Integer);
var
  aTableName, aMsg: string;
  aIPHE004_Min: TDateTime;
begin
  with qrChangLog do
  begin
    if not Active then Exit;
    if RecordCount = 0 then Exit;
    First;
    aTableName := UpperCase(FieldByName('TABLE_NAME').AsString);

    if ListBox_Monitor.Items.IndexOf(aTableName) >= 0 then
    begin
      aIPHE004_Min := IncDay(Now, -10);

      while not Eof do
      begin
        if (aTableName = 'WICSIPHE') and (FieldByName('OP').AsString = 'U') and
           (FieldByName('IPHE004').AsDateTime < aIPHE004_Min) then
        begin
          Next;
          Continue;
        end;
        // Added by Joe 2018/05/08 09:48:07
        if (aTableName = 'WICSIPHE') and FieldByName('IPHE004').IsNull and (FieldByName('OP').AsString <> 'D') then
        begin
          Next;
          Continue;
        end;
        //---------------------------------------------------------------------
        aMsg := GetMsg_ChangLog;

        try
          SendNotify(aMsg);
          //FLastLogID[ATableNdx] := FieldByName('REC_ID').AsInteger;
        except
          //IdTCPClient_Phone.Disconnect;
        end;
        Next;
      end;
    end;
    Last;
    FLastLogID[ATableNdx] := FieldByName('REC_ID').AsInteger;
    Close;
  end;
end;

function TfmMain.GetMsg_ChangLog: string;
begin
  (*
  'C:\TCRM\TriggerAp.EXE ' + Convert(varchar(30), @IPHE001) + ';I;WICSIPHE'
  'C:\TCRM\TriggerAp.EXE ' + Convert(varchar(30), @IPHE001) + ';U;WICSIPHE'
  'C:\TCRM\TriggerAp.EXE ' + Convert(varchar(30), @IPHE001) + ';D;WICSIPHE'
  *)
  with qrChangLog do
  begin
    Result := Format('%s;%s;%s', [FieldByName('EXTRA').AsString,
      FieldByName('OP').AsString, FieldByName('TABLE_NAME').AsString]);
  end;
  WriteLog(Format('%s', [Result]));
end;

procedure TfmMain.StoreConfig;
var
  aIniFileName: string;
  aIni: TIniFile;
  i: Integer;
begin
  inherited;
  aIniFileName := ChangeFileExt(Application.ExeName, '.ini');
  aIni := TIniFile.Create(aIniFileName);

  with aIni do
  begin
    WriteString('System', 'Host', Edit_Host.Text);
    WriteString('System', 'Port', Edit_Port.Text);
    WriteString('System', 'SQL', Edit_SQL.Text);

    for i := 0 to ListBox_Monitor.Items.Count-1 do
      WriteString('Monitor', 'M'+IntToSTr(i), ListBox_Monitor.Items[i]);
  end;

  aIni.Free;
end;

procedure TfmMain.RestoreConfig;
var
  aIniFileName: string;
  aIni: TIniFile;
  i: Integer;
begin
  inherited;
  aIniFileName := ChangeFileExt(Application.ExeName, '.ini');
  aIni := TIniFile.Create(aIniFileName);

  with aIni do
  begin
    Edit_Host.Text := ReadString('System', 'Host', '127.0.0.1');
    Edit_Port.Text := ReadString('System', 'Port', '9311');
    Edit_SQL.Text  := ReadString('System', 'SQL', '127.0.0.1');
    FCommKind := ReadString('System', 'CommKind', 'UDP'); // Added by Joe 2018/04/16 17:27:48

    ReadSectionValues('Monitor', ListBox_Monitor.Items);

    for i := 0 to ListBox_Monitor.Items.Count-1 do
      ListBox_Monitor.Items[i] := ListBox_Monitor.Items.Values['M'+IntToStr(i)];

    SetAdoConnection(Edit_SQL.Text);

    IdTCPClient_Phone.Host := Edit_Host.Text;
    IdTCPClient_Phone.Port := StrToIntDef(Edit_Port.Text, 9310);
  end;

  aIni.Free;
end;

procedure TfmMain.SetAdoConnection(AServer: string);
const
  DB_CONN_STR = 'Provider=SQLOLEDB.1;Password=hellotcrm;Persist Security Info=True;User ID=tcrm;Initial Catalog=WCRM;Data Source=%s';
begin
  with TcrmConn do
  begin
    if Connected then
      Connected := False;

    ConnectionString := Format(DB_CONN_STR, [AServer]);
  end;
end;

procedure TfmMain.N1Click(Sender: TObject);
begin
	Application.Terminate;
end;

end.
