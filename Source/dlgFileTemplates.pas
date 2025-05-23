{-----------------------------------------------------------------------------
 Unit Name: dlgCodeTemplates
 Author:    Kiriakos Vlahos
 Date:      08-Aug-2006
 Purpose:   Customization dialog for Code Templates
 History:
-----------------------------------------------------------------------------}

unit dlgFileTemplates;

interface

uses
  System.UITypes,
  System.Classes,
  System.Actions,
  System.ImageList,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ActnList,
  Vcl.ComCtrls,
  Vcl.ExtCtrls,
  Vcl.ImgList,
  Vcl.VirtualImageList,
  SynEdit,
  cFileTemplates,
  dlgPyIDEBase;

type
  TFileTemplatesDialog = class(TPyIDEDlgBase)
    Panel: TPanel;
    GroupBox: TGroupBox;
    SynTemplate: TSynEdit;
    TBXButton1: TButton;
    TBXButton3: TButton;
    TBXButton4: TButton;
    TBXButton5: TButton;
    TBXButton2: TButton;
    btnCancel: TButton;
    btnOK: TButton;
    btnHelp: TButton;
    ActionList: TActionList;
    actUpdateItem: TAction;
    actMoveDown: TAction;
    actMoveUp: TAction;
    actDeleteItem: TAction;
    actAddItem: TAction;
    Label1: TLabel;
    Label2: TLabel;
    Label5: TLabel;
    Label4: TLabel;
    Label3: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    lvItems: TListView;
    CBHighlighters: TComboBox;
    edName: TEdit;
    edCategory: TEdit;
    edExtension: TEdit;
    vilImages: TVirtualImageList;
    procedure FormDestroy(Sender: TObject);
    procedure ActionListUpdate(Action: TBasicAction; var Handled: Boolean);
    procedure actAddItemExecute(Sender: TObject);
    procedure actDeleteItemExecute(Sender: TObject);
    procedure actUpdateItemExecute(Sender: TObject);
    procedure actMoveUpExecute(Sender: TObject);
    procedure actMoveDownExecute(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure CBHighlightersChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure lvItemsSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
  private
    FOldIndex: Integer;
    FTempFileTemplates: TFileTemplates;
    procedure StoreFieldsToFileTemplate(FileTemplate: TFileTemplate);
    procedure AskToUpdate(Sender: TObject);
  public
    procedure SetItems;
    procedure GetItems;
  end;

implementation

uses
  System.SysUtils,
  System.Contnrs,
  Vcl.Graphics,
  Vcl.Dialogs,
  Vcl.Themes,
  SynEditHighlighter,
  JvGnugettext,
  uCommonFunctions,
  dmResources,
  StringResources;

{$R *.dfm}

procedure TFileTemplatesDialog.FormCreate(Sender: TObject);
begin
  inherited;
  FOldIndex := -1;
  FTempFileTemplates := TFileTemplates.Create;
  for var Highlighter in ResourcesDataModule.Highlighters do
    CBHighlighters.Items.AddObject(_(Highlighter.FriendlyLanguageName),
      Highlighter);
  SynTemplate.Highlighter := nil;
  ResourcesDataModule.ParameterCompletion.Editor := SynTemplate;
  ResourcesDataModule.ModifierCompletion.Editor := SynTemplate;
  // Styling
  SynTemplate.Color := StyleServices.GetSystemColor(clWindow);
  SynTemplate.Font.Color := StyleServices.GetSystemColor(clWindowText);
end;

procedure TFileTemplatesDialog.FormDestroy(Sender: TObject);
begin
  FTempFileTemplates.Free;
end;

procedure TFileTemplatesDialog.GetItems;
begin
  FileTemplates.Assign(FTempFileTemplates);
end;

procedure TFileTemplatesDialog.AskToUpdate(Sender: TObject);
begin
  if (edName.Text <> '') and SynTemplate.Modified then
  begin
    if (StyledMessageDlg(_(SCodeTemplateModified), mtConfirmation, [mbYes, mbNo], 0) = mrYes) then
      actUpdateItemExecute(Sender);
  end;
end;

procedure TFileTemplatesDialog.StoreFieldsToFileTemplate(FileTemplate: TFileTemplate);
begin
  FileTemplate.Name := edName.Text;
  FileTemplate.Extension := edExtension.Text;
  FileTemplate.Category := edCategory.Text;
  FileTemplate.Highlighter := (CBHighlighters.Items.Objects[CBHighlighters.ItemIndex] as
    TSynCustomHighlighter).LanguageName;
  FileTemplate.Template := SynTemplate.Text;
end;

procedure TFileTemplatesDialog.SetItems;
begin
  FTempFileTemplates.Assign(FileTemplates);
  lvItems.Items.BeginUpdate;
  try
    lvItems.Items.Clear;
    for var I := 0 to FTempFileTemplates.Count - 1 do
      with lvItems.Items.Add do begin
        Caption := (FTempFileTemplates[I] as TFileTemplate).Name;
        Data := FTempFileTemplates[I];
        SubItems.Add(TFileTemplate(FTempFileTemplates[I]).Category);
      end;
  finally
    lvItems.Items.EndUpdate;
  end;
end;

procedure TFileTemplatesDialog.ActionListUpdate(Action: TBasicAction;
  var Handled: Boolean);
begin
  actDeleteItem.Enabled := lvItems.ItemIndex >= 0;
  actMoveUp.Enabled := lvItems.ItemIndex >= 1;
  actMoveDown.Enabled := (lvItems.ItemIndex >= 0) and
                         (lvItems.ItemIndex < lvItems.Items.Count - 1);
  actAddItem.Enabled := (edName.Text <> '') and (edCategory.Text <> '');
  actUpdateItem.Enabled := (edName.Text <> '') and (lvItems.ItemIndex >= 0);
  Handled := True;
end;

procedure TFileTemplatesDialog.actAddItemExecute(Sender: TObject);
var
  Item: TListItem;
  FileTemplate: TFileTemplate;
begin
  if (edName.Text <> '') and (edCategory.Text <> '') then begin
    for var I := 0 to lvItems.Items.Count - 1 do
      if (CompareText(lvItems.Items[I].Caption, edName.Text) = 0) and
         (CompareText(lvItems.Items[I].SubItems[0], edCategory.Text) = 0) then
      begin
        Item := lvItems.Items[I];
        FileTemplate := TFileTemplate(Item.Data);
        StoreFieldsToFileTemplate(FileTemplate);
        Item.Caption := edName.Text;
        Item.SubItems[0] := edCategory.Text;
        Item.Selected := True;
        Item.MakeVisible(False);
        Exit;
      end;

    FileTemplate := TFileTemplate.Create;
    FTempFileTemplates.Add(FileTemplate);
    StoreFieldsToFileTemplate(FileTemplate);
    with lvItems.Items.Add do begin
      Caption := edName.Text;
      SubItems.Add(edCategory.Text);
      Data := FileTemplate;
      Selected := True;
      MakeVisible(False);
    end;
  end;
end;

procedure TFileTemplatesDialog.actDeleteItemExecute(Sender: TObject);
begin
  if lvItems.ItemIndex >= 0 then begin
    FTempFileTemplates.Delete(lvItems.ItemIndex);
    lvItems.Items.Delete(lvItems.ItemIndex);
  end;
end;

procedure TFileTemplatesDialog.actUpdateItemExecute(Sender: TObject);
begin
  if (edName.Text <> '') and (FOldIndex >= 0) then begin
    for var I := 0 to lvItems.Items.Count - 1 do
      if (CompareText(lvItems.Items[I].Caption, edName.Text) = 0) and
         (CompareText(lvItems.Items[I].SubItems[0], edCategory.Text) = 0) and
         (I <> FOldIndex) then
      begin
        StyledMessageDlg(_(SSameName), mtError, [mbOK], 0);
        Exit;
      end;
    with lvItems.Items[FOldIndex] do begin
      StoreFieldsToFileTemplate(TFileTemplate(Data));
      Caption := edName.Text;
      SubItems[0] := edCategory.Text;
      SynTemplate.Modified := False;
    end;
  end;
end;

procedure TFileTemplatesDialog.btnHelpClick(Sender: TObject);
begin
  Application.HelpContext(HelpContext);
end;

procedure TFileTemplatesDialog.CBHighlightersChange(Sender: TObject);
begin
  if CBHighlighters.ItemIndex < 0 then
    SynTemplate.Highlighter := nil
  else
    SynTemplate.Highlighter :=
      CBHighlighters.Items.Objects[CBHighlighters.ItemIndex] as TSynCustomHighlighter;
end;

procedure TFileTemplatesDialog.lvItemsSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
var
  FileTemplate: TFileTemplate;
begin
  if Selected then begin
    FOldIndex := Item.Index;
    FileTemplate := TFileTemplate(Item.Data);
    edName.Text := FileTemplate.Name;
    edCategory.Text := FileTemplate.Category;
    edExtension.Text := FileTemplate.Extension;
    CBHighlighters.ItemIndex := CBHighlighters.Items.IndexOf(FileTemplate.Highlighter);
    SynTemplate.Text := FileTemplate.Template;
    CBHighlightersChange(Self);
  end else begin
    AskToUpdate(Sender);
    FOldIndex := -1;
    edName.Text := '';
    edCategory.Text := '';
    edExtension.Text := '';
    CBHighlighters.ItemIndex := -1;
    SynTemplate.Text := '';
  end;
  SynTemplate.Modified := False;
end;

procedure TFileTemplatesDialog.actMoveUpExecute(Sender: TObject);
var
  Name, Value: string;
  P: Pointer;
  Index: Integer;
begin
  if lvItems.ItemIndex > 0 then begin
    Index := lvItems.ItemIndex;
    Name := lvItems.Items[Index].Caption;
    Value := lvItems.Items[Index].SubItems[0];
    P := lvItems.Items[Index].Data;
    lvItems.Items.Delete(Index);

    with lvItems.Items.Insert(Index - 1) do begin
      Caption := Name;
      SubItems.Add(Value);
      Data := P;
      Selected := True;
    end;
    FTempFileTemplates.Move(Index, Index - 1);
  end;
end;

procedure TFileTemplatesDialog.actMoveDownExecute(Sender: TObject);
var
  Name, Value: string;
  P: Pointer;
  Index: Integer;
begin
  if lvItems.ItemIndex < lvItems.Items.Count - 1 then begin
    Index := lvItems.ItemIndex;
    Name := lvItems.Items[Index].Caption;
    Value := lvItems.Items[Index].SubItems[0];
    P := lvItems.Items[Index].Data;
    lvItems.Items.Delete(Index);

    with lvItems.Items.Insert(Index + 1) do begin
      Caption := Name;
      SubItems.Add(Value);
      Data := P;
      Selected := True;
    end;
    FTempFileTemplates.Move(Index, Index + 1);
  end;
end;

procedure TFileTemplatesDialog.FormClose(Sender: TObject; var Action:
    TCloseAction);
begin
  if (ModalResult = mrOk) then
    AskToUpdate(Sender);
  GetItems;
end;

end.
