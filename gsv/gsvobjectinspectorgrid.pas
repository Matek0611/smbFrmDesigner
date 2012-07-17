﻿{*******************************************************}
{                                                       }
{       Визуальный компонент инспектора объектов        }
{                                                       }
{                    Версия 1.19                        }
{                                                       }
{          Copyright (C) 2007. Сергей Гурин             }
{                                                       }
{ Особые благодарности:                                 }
{   Илья Киров (ikirov@bars-it.ru)                      }
{   Сергей Галездинов (sega-zero@yandex.ru)             }
{   Максим Гвоздев (max@papillon.ru)                    }
{                                                       }
{*******************************************************}
unit GsvObjectInspectorGrid;
// Ported to lazarus by Cynic 12/07/2012
{$MODE Delphi}

interface

uses
  Messages, Windows, Classes, SysUtils, Controls, StdCtrls, Forms,
  Graphics, ExtCtrls, MaskEdit,LCLType,LMessages,
  GsvObjectInspectorTypes;

const
  WM_GSV_OBJECT_INSPECTOR_SHOW_DIALOG = WM_USER;

type
  // опережающие определения классов
  TGsvCustomObjectInspectorGrid    = class;
  TGsvObjectInspectorInplaceEditor = class;

  // Список, хранящий историю отображения свойств объекта некоторого класса
  TGsvObjectInspectorHistory = class
  private
    FExpanded: array of Integer; // индексы свойств, у которых Expanded = True
    FCount:    Integer; // текущее число свойств в массиве

  public
    Selected: Integer;
    TopRow:   Integer;

    constructor Create;
    destructor  Destroy; override;
    procedure   Clear;
    procedure   Add(Index: Integer);
    function    Expanded(Index: Integer): Boolean;
    function    ToString(const aName: string): string;
    function    FromString(const aData: string): string;
  end;

  // Список дескрипторов всех свойств объекта
  TGsvObjectInspectorProperties = class
  private
    FInspector: TGsvCustomObjectInspectorGrid;
    FItems:     array of TGsvObjectInspectorPropertyInfo;
    FCount:     Integer;
    FHistory:   TStringList; // история хранит имена типов инспектируемых объектов
                             // и указатели на их истории
    FCurrentHistory: TGsvObjectInspectorHistory; // указатель на текущий список истории

    function GetItem(AIndex: Integer): PGsvObjectInspectorPropertyInfo;
    function HistoryName: String;

  public
    constructor Create(AInspector: TGsvCustomObjectInspectorGrid);
    destructor  Destroy; override;
    procedure   FillHistory(aHistory: TGsvObjectInspectorHistory);
    procedure   Clear;
    procedure   Add(Info: PGsvObjectInspectorPropertyInfo);
    function    TopRow: Integer;
    function    Selected: Integer;
    procedure   ExpandAll(Value: Boolean);
    function    SetLayout(const aData: string;
                out aTopRow, aSelected: Integer): Boolean;
    function    SetSelected(const aName: string): Integer;
    property    Count: Integer read FCount;
    property    Items[AIndex: Integer]: PGsvObjectInspectorPropertyInfo
                read GetItem; default;
  end;

  // Окно для отображения подсказок для длинных строк
  TGsvObjectInspectorHintWindow = class(TCustomControl)
  public
    constructor Create(AOwner: TComponent); override;

  private
    FInspector:   TGsvCustomObjectInspectorGrid;
    FMinShowTime: Cardinal; // минимальное время показа хинта (или 0)
    FMinHideTime: Cardinal; // минимальное время скрытия хинта
    FHideTime:    Cardinal; // время скрытия хинта
    FTextOffset:  Integer;  // смещение текста хинта от начала окна
    FTimer:       TTimer;   // таймер для управления хинтом

    procedure ActivateHint(const Rect: TRect; const AText: String;
              IsEditHint: Boolean);
    procedure HideLongHint(HardHide: Boolean = False);
    procedure OnTimer(Sender: TObject);

  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
              X, Y: Integer); override;
  public
    function  CanFocus: Boolean; override;
  end;

  // Компонент выпадающего списка строк
  TGsvObjectInspectorListBox = class(TCustomListBox)
  public
    constructor Create(AOwner: TComponent); override;

  private
    FEditor: TGsvObjectInspectorInplaceEditor;

    procedure HideList(Accept: Boolean);

    procedure WMRButtonDown(var Message: TWMRButtonDown); message WM_RBUTTONDOWN;
    procedure WMRButtonUp(var Message: TWMRButtonDown); message WM_RBUTTONUP;
    procedure WMMButtonDown(var Message: TWMMButtonDown); message WM_MBUTTONDOWN;
    procedure WMMButtonUp(var Message: TWMMButtonDown); message WM_MBUTTONUP;

  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
              X, Y: Integer); override;
  end;

  // Настраиваемый редактор значения свойства. Имеет поле редактирования и
  // возможную дополнительную кнопку с графическим образом списка или мастера
  TGsvObjectInspectorInplaceEditor = class(MaskEdit.TCustomMaskEdit)
  public
    constructor Create(AOwner: TComponent); override;

  private
    // собственные переменные
    FInspector:     TGsvCustomObjectInspectorGrid;
    FPropertyInfo:  PGsvObjectInspectorPropertyInfo; // дескриптор редактируемого свойства
    FListBox:       TGsvObjectInspectorListBox;      // окно выпадающего списка строк
    FButtonWidth:   Integer; // ширина кнопки
    FPressed:       Boolean; // вид отрисовываемой кнопки - нажата или отпущена
    FWasPressed:    Boolean; // кнопка была нажата, но еще не отпущена
    FLockModify:    Boolean; // блокировка модификации текста
    FDropDownCount: Integer; // скорректированный размер выпадающего списка

    procedure SetNewEditText(const Value: String);
    procedure ShowEditor(ALeft, ATop, ARight, ABottom: Integer;
              Info: PGsvObjectInspectorPropertyInfo;
              const Value: String);
    procedure HideEditor;
    procedure ShowEditHint;
    procedure ShowValueHint;
    procedure DropDown;
    procedure CloseUp(Accept: Boolean);
    procedure ListItemChanged;
    procedure SetListItem(Index: Integer);
    procedure ShowDialog;
    procedure ValidateStringValue(const Value: String);


    // события Windows
    procedure CMCancelMode(var Message: TLMessage); message LM_CANCELMODE;
    procedure WMPaint(var Message: TLMPaint); message LM_PAINT;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure WMLButtonDown(var Message: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMLButtonUp(var Message: TWMLButtonUp); message WM_LBUTTONUP;
    procedure WMLButtonDblClk(var Message: TWMLButtonDblClk); message WM_LBUTTONDBLCLK;
    procedure WMKillFocus(var Message: TMessage); message WM_KILLFOCUS;

  protected
    // переопределяемые методы базового класса
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure PaintWindow(DC: HDC); override;
    procedure DoExit; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    function  DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint):
              Boolean; override;
    function  DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint):
              Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;
    procedure Change; override;
    procedure ValidateError;

  public
    procedure ValidateEdit; override;
  end;

  // Типы обработчиков событий для инспектора объектов

  { Тип обработчика для перечисления всех свойств инспектируемого объекта.
    Обработчик события этого типа вернуть указатель дескриптора очередного
    свойства, индекс которого передается в аргументе Index. Перечисление
    начинается с индекса 0, причем при каждом последующем вызове индекс
    инкрементируется. Если все свойства перечислены и индекс очередного
    свойства указывает на свойство за последним, то обработчик события
    возвращает nil. Возврат указателя выполняется через параметр Info }
  TGsvObjectInspectorEnumPropertiesEvent = procedure(Sender: TObject;
    Index: Integer; out Info: PGsvObjectInspectorPropertyInfo) of object;

  { Тип обработчика для получения строкового представления значения свойства.
    Обработчик этого типа должен получить действительное значение свойства
    инспектируемого объекта, преобразовать в строковое представление и
    присвоить его аргументу Value }
  TGsvObjectInspectorGetStringValueEvent = procedure(Sender: TObject;
    Info: PGsvObjectInspectorPropertyInfo; out Value: String) of object;

  { Тип обработчика для установки значения свойства из его строкового
    представления. Обработчик этого типа должен преобразовать строковое
    представление значения к действительному типу свойства и установить
    его в инспектируемом объекте. Если в процессе преобразования возникла
    ошибка, то обработчик должен самостоятельно выполнить какие-либо действия,
    например, игнорировать ошибку, выдавать звуковой сигнал, выводить сообщение
    в виде диалога, отображать в строке статуса и т.д. }
  TGsvObjectInspectorSetStringValueEvent = procedure(Sender: TObject;
    Info: PGsvObjectInspectorPropertyInfo; const Value: String) of object;

  { Два этих типа подобны предыдущим, но предназначен для
    работы с целочисленным представлением значения свойства }
  TGsvObjectInspectorGetIntegerValueEvent = procedure(Sender: TObject;
    Info: PGsvObjectInspectorPropertyInfo; out Value: LongInt) of object;
  TGsvObjectInspectorSetIntegerValueEvent = procedure(Sender: TObject;
    Info: PGsvObjectInspectorPropertyInfo; const Value: LongInt) of object;

  { Тип обработчика для получения списка возможных значений свойства.
    Обработчик этого типа должен заполнить список List }
  TGsvObjectInspectorFillListEvent = procedure(Sender: TObject;
    Info: PGsvObjectInspectorPropertyInfo; List: TStrings) of object;

  { Тип обработчика для вызова диалога-мастера, который может выполнять
    установку некоторого составного или специфического свойства }
  TGsvObjectInspectorShowDialogEvent = procedure(Inspector: TComponent;
    Info: PGsvObjectInspectorPropertyInfo; const EditRect: TRect) of object;

  { Тип обработчика для отображения информации по свойству }
  TGsvObjectInspectorInfoEvent = procedure(Sender: TObject;
    Info: PGsvObjectInspectorPropertyInfo) of object;

  { Тип обработчика для преобразования названия свойства }
  TGsvObjectInspectorGetCaptionEvent = procedure(Sender: TObject;
    Info: PGsvObjectInspectorPropertyInfo; var aCaption: string) of object;

  TGsvObjectInspectorTreeChangeType = (tctNone, tctChange, tctCollapse,
                                       tctExpand);

  // Визуальный базовый компонент инспектора объектов
  TGsvCustomObjectInspectorGrid = class(TCustomControl)
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

  private
    // собственные переменные
    FProperties:       TGsvObjectInspectorProperties;    // список дескрипторов свойств инспектируемого объекта
    FEditor:           TGsvObjectInspectorInplaceEditor; // редактор свойства
    FHintWindow:       TGsvObjectInspectorHintWindow;    // окно хинта длинных строк
    FRows:             array of PGsvObjectInspectorPropertyInfo; // строки инспектора
    FGlyphs:           TBitmap; // графические образы
    FRowsCount:        Integer; // число отображаемых свойств
    FTopRow:           Integer; // индекс верхнего отображаемого свойства
    FSelected:         Integer; // индекс выделенного свойства
    FMouseDivPos:      Integer; // позиция мышки при перемещении линии разделителя
    FFontHeight:       Integer; // высота шрифта в пикселях
    FLevelIndent:      Integer; // отступ уровня в пикселях
    FInvalidateLock:   Boolean; // блокировка события SmartInvalidate
                                // в том случае, если событие происходит
                                // быстрее, чем может быть обработано

    // свойства
    FBorderStyle:      TBorderStyle; // стиль рамки
    FRowHeight:        Integer;      // высота строки инспектора, задается
                                     // независимо от размеров шрифта
    FDividerPosition:  Integer;      // позиция линии разделителя колонок
    FFolderFontColor:  TColor;       // цвет шрифта папок
    FFolderFontStyle:  TFontStyles;  // стиль шрифта папок
    FLongTextHintTime: Cardinal;     // время отображения хинта длинных строк.
                                     // Если 0, то не показывать хинты
    FLongEditHintTime: Cardinal;     // время отображения хинта при редактировании.
                                     // Если 0, то не показывать хинты
    FAutoSelect:       Boolean;      // выделять ли весь текст в редакторе свойства
                                     // при переходе к нему?
    FMaxTextLength:    Integer;      // максимальная длина строки значения
    FDropDownCount:    Integer;      // число строк выпадающего списка
    FHideReadOnly:     Boolean;      // показывать все свойства. Если этот
                                     // флаг равен True, то свойства вида
                                     // pkReadOnlyText не отображаются

    // методы установки свойств
    procedure SetBorderStyle(const Value: TBorderStyle);
    procedure SetRowHeight(const Value: Integer);
    procedure SetDividerPosition(const Value: Integer);
    procedure SetFolderFontColor(const Value: TColor);
    procedure SetFolderFontStyle(const Value: TFontStyles);
    procedure SetLongTextHintTime(const Value: Cardinal);
    procedure SetLongEditHintTime(const Value: Cardinal);
    procedure SetMaxTextLength(const Value: Integer);
    procedure SetHideReadOnly(const Value: Boolean);
    function  GetLayout: string;
    procedure SetLayout(const Value: string);

    // события Windows
    procedure CMCtl3DChanged(var Message: TMessage); message CM_CTL3DCHANGED;
    procedure WMVScroll(var Msg: TWMVScroll); message WM_VSCROLL;
    procedure WMGetDlgCode(var Msg: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WMShowDialog(var Message: TMessage);
              message WM_GSV_OBJECT_INSPECTOR_SHOW_DIALOG;
    procedure WMHelp(var aMessage: TMessage); message WM_HELP;

    // вспомогательные методы
    function  DividerHitTest(X: Integer): Boolean;
    procedure EnumProperties;
    procedure CreateRows;
    procedure UpdateScrollBar;
    procedure ShowLongHint(const Rect: TRect; const AText: String;
              IsEditHint: Boolean = False);
    procedure HideLongHint(HardHide: Boolean = False);
    procedure ShowEditor;
    procedure HideEditor;
    procedure UpdateEditor;
    procedure UpdateFocus;
    procedure SetTopRow(ATopRow: Integer);
    procedure SetSelectedRow(ARow: Integer);
    procedure SetSelectedRowByMouse(X, Y: Integer);
    procedure ChangeBoolean(Info: PGsvObjectInspectorPropertyInfo);
    procedure ExpandingOrChangeBoolean(ExpandingOnly: Boolean;
              ChangeType: TGsvObjectInspectorTreeChangeType);

    // экспортируемые вспомогательные методы для поля редактирования
    procedure SetSelectedRowByKey(Key: Word);
    procedure ValueChanged(Info: PGsvObjectInspectorPropertyInfo;
              const Value: String);

  protected
    // указатели событий
    FOnEnumProperties:  TGsvObjectInspectorEnumPropertiesEvent;
    FOnGetStringValue:  TGsvObjectInspectorGetStringValueEvent;
    FOnSetStringValue:  TGsvObjectInspectorSetStringValueEvent;
    FOnGetIntegerValue: TGsvObjectInspectorGetIntegerValueEvent;
    FOnSetIntegerValue: TGsvObjectInspectorSetIntegerValueEvent;
    FOnFillList:        TGsvObjectInspectorFillListEvent;
    FOnShowDialog:      TGsvObjectInspectorShowDialogEvent;
    FOnHelp:            TGsvObjectInspectorInfoEvent;
    FOnHint:            TGsvObjectInspectorInfoEvent;
    FOnGetCaption:      TGsvObjectInspectorGetCaptionEvent;

    // переопределяемые методы базового класса
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Paint; override;
    procedure Resize; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure Loaded; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState;
              X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState;
              X, Y: Integer); override;
    function  DoMouseWheelDown(Shift: TShiftState; MousePos: TPoint):
              Boolean; override;
    function  DoMouseWheelUp(Shift: TShiftState; MousePos: TPoint):
              Boolean; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    procedure KeyUp(var Key: Word; Shift: TShiftState); override;

    // Диспетчеры свойств
    function  DoGetStringValue(Info: PGsvObjectInspectorPropertyInfo):
              String; virtual;
    procedure DoSetStringValue(Info: PGsvObjectInspectorPropertyInfo;
              const Value: String); virtual;
    function  DoGetIntegerValue(Info: PGsvObjectInspectorPropertyInfo):
              LongInt; virtual;
    procedure DoSetIntegerValue(Info: PGsvObjectInspectorPropertyInfo;
              const Value: LongInt); virtual;
    procedure DoShowDialog; virtual;
    procedure DoFillList(Info: PGsvObjectInspectorPropertyInfo;
              List: TStrings); virtual;
    procedure DoHelp; virtual;
    procedure DoHint(Info: PGsvObjectInspectorPropertyInfo); virtual;
    function  DoGetCaption(Info: PGsvObjectInspectorPropertyInfo): string; virtual;

    // свойства для переопределения в классах-потомках
    property  BorderStyle: TBorderStyle read FBorderStyle
              write SetBorderStyle default bsSingle;
    property  RowHeight: Integer read FRowHeight
              write SetRowHeight;
    property  DividerPosition: Integer read FDividerPosition
              write SetDividerPosition;
    property  FolderFontColor: TColor read FFolderFontColor
              write SetFolderFontColor default clBtnText;
    property  FolderFontStyle: TFontStyles read FFolderFontStyle
              write SetFolderFontStyle default [fsBold];
    property  LongTextHintTime: Cardinal read FLongTextHintTime
              write SetLongTextHintTime default 3000;
    property  LongEditHintTime: Cardinal read FLongEditHintTime
              write SetLongEditHintTime default 3000;
    property  AutoSelect: Boolean read FAutoSelect
              write FAutoSelect default True;
    property  MaxTextLength: Integer read FMaxTextLength
              write SetMaxTextLength default 256;
    property  DropDownCount: Integer read FDropDownCount
              write FDropDownCount default 8;
    property  HideReadOnly: Boolean read FHideReadOnly
              write SetHideReadOnly default False;

    // события для переопределения в классах-потомках
    property  OnEnumProperties: TGsvObjectInspectorEnumPropertiesEvent
              read FOnEnumProperties write FOnEnumProperties;
    property  OnGetStringValue: TGsvObjectInspectorGetStringValueEvent
              read FOnGetStringValue write FOnGetStringValue;
    property  OnSetStringValue: TGsvObjectInspectorSetStringValueEvent
              read FOnSetStringValue write FOnSetStringValue;
    property  OnGetIntegerValue: TGsvObjectInspectorGetIntegerValueEvent
              read FOnGetIntegerValue write FOnGetIntegerValue;
    property  OnSetIntegerValue: TGsvObjectInspectorSetIntegerValueEvent
              read FOnSetIntegerValue write FOnSetIntegerValue;
    property  OnFillList: TGsvObjectInspectorFillListEvent
              read FOnFillList write FOnFillList;
    property  OnShowDialog: TGsvObjectInspectorShowDialogEvent
              read FOnShowDialog write FOnShowDialog;
    property  OnHelp: TGsvObjectInspectorInfoEvent
              read FOnHelp write FOnHelp;
    property  OnHint: TGsvObjectInspectorInfoEvent
              read FOnHint write FOnHint;
    property  OnGetCaption: TGsvObjectInspectorGetCaptionEvent
              read FOnGetCaption write FOnGetCaption;

  public
    procedure NewObject;
    procedure Clear;
    procedure AcceptChanges;
    procedure SmartInvalidate;
    procedure ExpandAll;
    procedure CollapseAll;
    function  InplaceEditor: TCustomEdit;
    function  SelectedLeftBottom: TPoint;
    function  SelectedCenter: TPoint;
    function  SelectedInfo: PGsvObjectInspectorPropertyInfo;
    function  SelectedText: string;
    procedure SetSelected(const aName: string);
    procedure ValidateStringValue(const Value: String);
    property  Layout: string read GetLayout write SetLayout;
  end;

  TGsvObjectInspectorGrid = class(TGsvCustomObjectInspectorGrid)
  published
    // наследуемые свойства от TCustomControl и его родителей
    property Align;
    property Anchors;
   // property BevelInner;
 //   property BevelOuter;
 //   property BevelWidth;
  //  property BevelKind;
    property Constraints;
  //  property Ctl3D;
 //   property ParentCtl3D;
    property Enabled;
    property ParentFont;
    property Font;
    property TabStop;
    property TabOrder;
    property Visible;

    // наследуемые свойства от TGsvCustomObjectInspectorGrid
    property BorderStyle;
    property RowHeight;
    property DividerPosition;
    property FolderFontColor;
    property FolderFontStyle;
    property LongTextHintTime;
    property LongEditHintTime;
    property AutoSelect;
    property MaxTextLength;
    property DropDownCount;
    property HideReadOnly;

    // наследуемые события от TCustomControl и его родителей
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnResize;

    // наследуемые события от TGsvCustomObjectInspectorGrid
    property OnEnumProperties;
    property OnGetStringValue;
    property OnSetStringValue;
    property OnGetIntegerValue;
    property OnSetIntegerValue;
    property OnFillList;
    property OnShowDialog;
    property OnHelp;
    property OnHint;
    property OnGetCaption;
  end;

procedure Register;

implementation


uses
  Math, RTLConsts;
procedure Register;
begin
  RegisterComponents('Gsv', [TGsvObjectInspectorGrid]);
end;
const
  DIVIDER_LIMIT     = 30;  // минимальное значение ширины колонок инспектора
  BUTTON_POINT_SIZE = 2;   // размер точки для графического образа pkDialog
  VALUE_LEFT_MARGIN = 1;   // отступ от левого края для вывода строки значения
  GLYPH_MAGRIN      = 1;   // отступ от краев графического образа древовидного списка
  GLYPH_TREE_SIZE   = 9;   // размер образов + и - дерева
  GLYPH_CHECK_SIZE  = 11;  // размер образов CheckBox'a
  HINT_TEXT_OFFSET  = 16;  // смещение текста хинта в режиме редактирования
  PROP_LIST_DELTA   = 32;  // размер, на который будет увеличиваться список объектов
  HISTORY_DELTA     = 8;   // размер, на который будет увеличиваться список истории
  COLOR_RECT_WIDTH  = 20;  // ширина цветного прямоугольника
  COLOR_RECT_HEIGHT = 9;   // высота цветного прямоугольника
  TEXT_LIMIT        = 200; // длина текста строки. При превышении она выводится с ...
  VK_OEM_MINUS      = $BD;
  VK_OEM_PLUS       = $BB;


// Определитель различных признаков свойств
type
  TGsvKindSelector = (
    _EDITOR,         // свойство имеет редактор
    _BUTTON,         // свойство имеет редактор с кнопкой
    _READONLY,       // свойство только для чтения
    _INPUT_TEXT,     // свойство с установкой значения из текстового представления
    _LIST,           // свойство имеет список
    _DIALOG,         // свойство имеет кнопку диалога-мастера
    _INTEGER         // свойство имеет целочисленное представление
  );

function HAS(That: TGsvKindSelector; Info: PGsvObjectInspectorPropertyInfo):
  Boolean;
const
  DSK: array[TGsvObjectInspectorPropertyKind, TGsvKindSelector] of Boolean = (
    {                 EDITOR BUTTON READON INPUT  LIST   DIALOG INTEG}
    {None}           (False, False, False, False, False, False, False ),
    {Text}           (True,  False, False, True,  False, False, False ),
    {DropDownList}   (True,  True,  True,  True,  True,  False, True  ),
    {Dialog}         (True,  True,  True,  False, False, True,  False ),
    {Folder}         (False, False, True,  False, False, False, False ),
    {ReadOnlyText}   (False, False, True,  False, False, False, False ),
    {Boolean}        (False, False, False, False, False, False, True  ),
    {ImmediateText}  (True,  False, False, True,  False, False, False ),
    {TextList}       (True,  True,  False, True,  True,  False, False ),
    {Set}            (True,  False, True,  False, False, False, True  ),
    {Color}          (True,  True,  True,  True,  True,  False, True  ),
    {ColorRGB}       (True,  True,  False, True,  False, True,  True  ),
    {Float}          (True,  False, False, True,  False, False, False ),
    {TextDialog}     (True,  True,  False, True,  False, True,  False )
  );
begin
  if Assigned(Info) then Result := DSK[Info^.Kind, That]
  else                   Result := False;
end;

function TextWithLimit(const s: String): String;
begin
  Result := s;
  if Length(Result) > TEXT_LIMIT then begin
    SetLength(Result, TEXT_LIMIT);
    Result := Result + '...';
  end;
end;

{ TGsvObjectInspectorHistory }

constructor TGsvObjectInspectorHistory.Create;
begin
  SetLength(FExpanded, HISTORY_DELTA);
  Clear;
end;

destructor TGsvObjectInspectorHistory.Destroy;
begin
  FExpanded := nil;
  inherited;
end;

procedure TGsvObjectInspectorHistory.Clear;
begin
  Selected := -1;
  FCount   := 0;
end;

// Добавление индекса свойства, у которого Expanded = True.
// Индексы добавляются в порядке возрастания
procedure TGsvObjectInspectorHistory.Add(Index: Integer);
begin
  // если необходимо, то увеличение размера массива
  if FCount > High(FExpanded) then
    SetLength(FExpanded, Length(FExpanded) + HISTORY_DELTA);
  FExpanded[FCount] := Index;
  Inc(FCount);
end;

// Двоичный поиск в упорядоченном массиве индексов
function TGsvObjectInspectorHistory.Expanded(Index: Integer): Boolean;
var
  L, H, I: Integer;
begin
  Result := False;
  L      := 0;
  H      := FCount - 1;
  while L <= H do begin
    I := (L + H) shr 1;
    if FExpanded[I] < Index then
      L := I + 1
    else begin
      H := I - 1;
      if FExpanded[I] = Index then begin
        Result := True;
        Break;
      end;
    end;
  end;
end;


function TGsvObjectInspectorHistory.ToString(const aName: string): string;
var
  lst: TStringList;
  i:   Integer;
begin
  Result := '';
  lst    := TStringList.Create;
  try
    lst.Add(aName);
    lst.Add(IntToStr(TopRow));
    lst.Add(IntToStr(Selected));
    for i := 0 to Pred(FCount) do
      lst.Add(IntToStr(FExpanded[i]));
    Result := lst.CommaText;
  finally
    lst.Free;
  end;
end;

function TGsvObjectInspectorHistory.FromString(const aData: string): string;
var
  lst: TStringList;
  i:   Integer;
begin
  Result := '';
  lst    := TStringList.Create;
  try
    lst.CommaText := aData;
    if lst.Count >= 3 then begin
      FCount := lst.Count - 3;
      SetLength(FExpanded, FCount);
      TopRow   := StrToIntDef(lst.Strings[1], 0);
      Selected := StrToIntDef(lst.Strings[2], -1);
      for i := 3 to Pred(lst.Count) do
        FExpanded[i - 3] := StrToIntDef(lst.Strings[i], -1);
      Result := lst.Strings[0];
    end;
  finally
    lst.Free;
  end;
end;

{ TGsvObjectInspectorProperties }

function TGsvObjectInspectorProperties.GetItem(
  AIndex: Integer): PGsvObjectInspectorPropertyInfo;
begin
  Assert((AIndex >= 0) and (AIndex < FCount));
  Result := @FItems[AIndex];
end;

function TGsvObjectInspectorProperties.HistoryName: String;
var
  obj: TObject;
begin
  Result := '';
  if Length(FItems) = 0 then
    Exit;
  obj := FItems[0].TheObject;
  if not Assigned(obj) then
    Exit;
  Result := obj.ClassName;
  if FInspector.FHideReadOnly then
    Result := Result + '_HRO';
end;

constructor TGsvObjectInspectorProperties.Create(
  AInspector: TGsvCustomObjectInspectorGrid);
begin
  inherited Create;
  FInspector := AInspector;
  SetLength(FItems, PROP_LIST_DELTA);
  FHistory            := TStringList.Create;
  FHistory.Sorted     := True;
  FHistory.Duplicates := dupIgnore;
end;

destructor TGsvObjectInspectorProperties.Destroy;
var
  i: Integer;
begin
  for i := 0 to Pred(FHistory.Count) do
    FHistory.Objects[i].Free;
  FHistory.Free;
  FItems := nil;
  inherited;
end;

procedure TGsvObjectInspectorProperties.FillHistory(aHistory:
  TGsvObjectInspectorHistory);
var
  i: Integer;
begin
  // сохраняем в списке индексы всех свойств с Expanded = True
  for i := 0 to Pred(FCount) do
    if FItems[i].HasChildren and FItems[i].Expanded then
      aHistory.Add(i);
  aHistory.TopRow   := FInspector.FTopRow;
  aHistory.Selected := FInspector.FSelected;
end;

procedure TGsvObjectInspectorProperties.Clear;
var
  nm:  String;
  ind: Integer;
  lst: TGsvObjectInspectorHistory;
begin
  FCurrentHistory := nil;
  if FCount = 0 then
    Exit;
  // перед очисткой сохраняем индексы свойств, у которых Expanded = True
  nm := HistoryName;
  if nm <> '' then begin
    ind := -1;
    // ищем в истории класс с текущим именем, если его нет, то создаем новый
    if not FHistory.Find(nm, ind) then begin
      // добавляем в историю новый класс и создаем для него список
      FHistory.AddObject(nm, TGsvObjectInspectorHistory.Create);
      FHistory.Find(nm, ind);
    end;
    Assert((ind >= 0) and (ind < FHistory.Count));
    lst := FHistory.Objects[ind] as TGsvObjectInspectorHistory;
    lst.Clear;
    FillHistory(lst);
  end;
  FCount := 0;
end;

// Добавление нового свойства в список свойств объекта
procedure TGsvObjectInspectorProperties.Add(
  Info: PGsvObjectInspectorPropertyInfo);
var
  i: Integer;
begin
  if not Assigned(Info) then
    Exit;
  if not Assigned(Info^.TheObject) then
    Exit;
  if Info^.Level < 0 then
    Exit;
  if FCount = 0 then
    FCurrentHistory := nil
  else if Info^.Level > (FItems[FCount - 1].Level + 1) then
    Exit;
  if FCount > High(FItems) then
    SetLength(FItems, Length(FItems) + PROP_LIST_DELTA);
  FItems[FCount]             := Info^;
  FItems[FCount].HasChildren := False;
  FItems[FCount].Expanded    := False;
  if FCount <> 0 then begin
    if Info^.Level > FItems[FCount - 1].Level then begin
      // свойство имеет дочерние, берем из истории его расширение
      FItems[FCount - 1].HasChildren := True;
      if Assigned(FCurrentHistory) then
        FItems[FCount - 1].Expanded := FCurrentHistory.Expanded(FCount - 1);
    end;
  end
  else begin
    // ищем в истории класс с тем же именем и получаем список его расширенных свойств
    if FHistory.Find(HistoryName, i) then
      FCurrentHistory := FHistory.Objects[i] as TGsvObjectInspectorHistory
  end;
  Inc(FCount);
end;

function TGsvObjectInspectorProperties.TopRow: Integer;
begin
  if Assigned(FCurrentHistory) then
    Result := FCurrentHistory.TopRow
  else
    Result := -1;
end;

function TGsvObjectInspectorProperties.Selected: Integer;
begin
  if Assigned(FCurrentHistory) then
    Result := FCurrentHistory.Selected
  else
    Result := 0;
end;


procedure TGsvObjectInspectorProperties.ExpandAll(Value: Boolean);
var
  i: Integer;
begin
  for i := 0 to Pred(FCount) do
    if FItems[i].HasChildren then
      FItems[i].Expanded := Value;
end;

function TGsvObjectInspectorProperties.SetLayout(const aData: string;
  out aTopRow, aSelected: Integer): Boolean;
var
  h: TGsvObjectInspectorHistory;
  i: Integer;
begin
  Result    := False;
  aTopRow   := -1;
  aSelected := -1;
  h := TGsvObjectInspectorHistory.Create;
  try
    if h.FromString(aData) = HistoryName then begin
      aTopRow   := h.TopRow;
      aSelected := h.Selected;
      Result    := (aTopRow >= 0) and (aSelected >= 0);
      if Result then begin
        for i := 0 to Pred(FCount) do begin
          if FItems[i].HasChildren then
            FItems[i].Expanded := h.Expanded(i);
        end;
      end;
    end;
  finally
    h.Free;
  end;
end;

function TGsvObjectInspectorProperties.SetSelected(
  const aName: string): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to Pred(FCount) do begin
    if FItems[i].HasChildren then
      FItems[i].Expanded := True;
    if FItems[i].Name = aName then begin
      Result := i;
      Break;
    end;
  end;
end;

{ TGsvObjectInspectorHintWindow }

constructor TGsvObjectInspectorHintWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle       := ControlStyle + [csOpaque];
  FInspector         := AOwner as TGsvCustomObjectInspectorGrid;
  Parent             := FInspector;
  ParentColor        := True;
  //ParentCtl3D        := True;
  Color              := FInspector.Color;
  Canvas.Brush.Color := clInfoBk;
  Canvas.Font        := FInspector.Font;
  Canvas.Font.Color  := clInfoText;
  ShowHint           := False;
  TabStop            := False;
  Visible            := False;
  DoubleBuffered     := True;  // устранение мерцания при изменении текста
  FTimer             := TTimer.Create(Self);
  FTimer.Enabled     := False;
  FTimer.Interval    := 100;
  FTimer.OnTimer     := OnTimer;
end;

// Отображение хинта. Аргумент IsEditHint равен True для случая
// использования хинта при редактировании длинной строки
procedure TGsvObjectInspectorHintWindow.ActivateHint(const Rect: TRect;
  const AText: String; IsEditHint: Boolean);
var
  r:  TRect;
  p0: TPoint;
  dx: Integer;
const
  MIN_TIME = 300;
begin
  // запрет хинтов при отображении выпадающего списка редактора
  if Assigned(FInspector.FEditor) then begin
    if Assigned(FInspector.FEditor.FListBox) then
      if FInspector.FEditor.FListBox.Visible then
        Exit;
  end;
  // проверяем возможность отображения хинта
  if FMinShowTime <> 0 then begin
    if GetTickCount < FMinShowTime then
      Exit;
  end;
  FMinShowTime := 0;
  if IsRectEmpty(Rect) or (AText = '') then
    HideLongHint
  else begin
    // если время отображения хинта меньше MIN_TIME, то хинт вообще не показываем
    if IsEditHint then begin
      if FInspector.FLongEditHintTime < MIN_TIME then
        Exit;
      FTextOffset := HINT_TEXT_OFFSET;
      FHideTime   := GetTickCount + FInspector.FLongEditHintTime;
    end
    else begin
      if FInspector.FLongEditHintTime < MIN_TIME then
        Exit;
      FTextOffset := 0;
      FHideTime   := GetTickCount + FInspector.FLongTextHintTime;
    end;
    // расчет координат окна хинта
    p0 := FInspector.ClientToScreen(Point(0, 0));
    SetRect(r, p0.X + Rect.Left, p0.Y + Rect.Top,
      p0.X + Rect.Right, p0.Y + Rect.Bottom);
    // корректировка по размерам экрана
    dx := r.Right - Screen.Width;
    if dx > 0 then begin
      Dec(r.Left, dx);
      Dec(r.Right, dx);
    end;
    Dec(r.Left, FTextOffset);
    if r.Left < 0 then
      r.Left := 0;
    SetBounds(r.Left, r.Top, r.Right - r.Left, r.Bottom - r.Top);
    Hint := AText;
    // Если хинт предназначен для отображения редактируемой строки,
    // то отображаем хинт сразу, а иначе с задержкой для
    // предотвращения мелькания длинных хинтов. Задержка выполняется
    // на один тик таймера
    if IsEditHint then begin
      if not Visible then
        Show;
      Invalidate;
      // перемещаем указатель мыши на начало хинта, чтобы он не
      // мешал редактированию
      Mouse.CursorPos := ClientToScreen(Point(FTextOffset div 2, 6));
      Cursor          := crUpArrow;
    end;
    // запускаем таймер
    FTimer.Tag     := 1;
    FTimer.Enabled := True;
    FMinHideTime   := GetTickCount + 200;
  end;
end;

// Скрытие хинта. Если аргумент жесткого сброса хинта HardHide равен True,
// то сбрасываем хинт без контроля минимального времени
procedure TGsvObjectInspectorHintWindow.HideLongHint(HardHide: Boolean);
begin
  // контролируем возможность скрытия
  if not HardHide and (GetTickCount < FMinHideTime) then
    Exit;
  FTimer.Enabled := False;
  FTimer.Tag     := 0;
  if Visible then begin
    Hide;
    Hint        := '';
    FTextOffset := 0;
    Cursor      := crDefault;
  end;
  // если жесткий сброс, то запрещаем появление следующего хинта на 2 сек
  if HardHide then
    FMinShowTime := GetTickCount + 2000;
end;

// Обработчик таймера хинта. Таймер работает с интервалом 0.1 сек
procedure TGsvObjectInspectorHintWindow.OnTimer(Sender: TObject);
begin
  if PtInRect(GetClientRect, ScreenToClient(Mouse.CursorPos)) then begin
    // отображаем хинт
    if FTimer.Tag = 1 then begin
      FTimer.Tag := 2;
      if not Visible then
        Show;
      Invalidate;
      Exit;
    end;
    // проверяем истечение времени показа хинта
    if FTimer.Tag = 2 then begin
      if GetTickCount < FHideTime then
        Exit;
      // иначе истекло время отображения хинта, запрещаем его появление
      // ранее, чем через 300 мс
      FMinShowTime := GetTickCount + 300;
    end;
  end
  else
    // если мышь ушла с области хинта, то разрешаем быстрое скрытие
    FMinHideTime := GetTickCount;
  FTimer.Enabled := False;
  FTimer.Tag     := 0;
  HideLongHint;
end;

procedure TGsvObjectInspectorHintWindow.CreateParams(
  var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params do begin
    // всплывающее окно, которое может выходить за границы родительского
    // окна, и имеющее рамку
    Style := WS_POPUP or WS_BORDER;
    // сохранять область под окном при отображении окна и восстанавливать
    // ее при скрытии без посылки уведомления о перерисовке перекрытому окну
    WindowClass.Style := WindowClass.Style or CS_SAVEBITS;
  end;
end;

procedure TGsvObjectInspectorHintWindow.Paint;
var
  r:  TRect;
  dy: Integer;
begin
  r  := ClientRect;
  dy := (ClientHeight - FInspector.FFontHeight) div 2;
  // проверяем измененность шрифта инспектора
  if Canvas.Font.Name <> FInspector.Font.Name then
    Canvas.Font.Name := FInspector.Font.Name;
  if Canvas.Font.Size <> FInspector.Font.Size then
    Canvas.Font.Size := FInspector.Font.Size;
  // закрашиваем клиентскую область хинта
  Canvas.FillRect(r);
  // отображаем текст
  Canvas.TextOut(1 + FTextOffset, dy, Hint);
end;

// Принудительное закрытие хинта
procedure TGsvObjectInspectorHintWindow.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  p: TPoint;
begin
  inherited;
  HideLongHint(True);
  FInspector.SetFocus;
  FInspector.UpdateFocus;
  if Button = mbLeft then begin
    // переводим положение мыши в координаты инспектора
    p := FInspector.ScreenToClient(ClientToScreen(Point(X, y)));
    // Делаем попытку выделения свойства под хинтом
    FInspector.SetSelectedRowByMouse(p.X, p.Y);
  end;
end;

function TGsvObjectInspectorHintWindow.CanFocus: Boolean;
begin
  Result := False;
end;


{ TGsvObjectInspectorListBox }

constructor TGsvObjectInspectorListBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEditor        := AOwner as TGsvObjectInspectorInplaceEditor;
  TabStop        := False;
  Visible        := False;
 // Ctl3D          := False;
 // ParentCtl3D    := False;
  ParentFont     := True;
  Color          := clWindow;
  ParentColor    := False;
  ShowHint       := False;
  ParentShowHint := False;
  IntegralHeight := True;
  TabStop        := False;
end;

// Закрытие списка
procedure TGsvObjectInspectorListBox.HideList(Accept: Boolean);
begin
  FEditor.CloseUp(Accept);
end;

// Запрещаем функции средней и правой кнопок мышки
procedure TGsvObjectInspectorListBox.WMRButtonDown(var Message: TWMRButtonDown);
begin
end;
procedure TGsvObjectInspectorListBox.WMRButtonUp(var Message: TWMRButtonDown);
begin
end;
procedure TGsvObjectInspectorListBox.WMMButtonDown(var Message: TWMMButtonDown);
begin
end;
procedure TGsvObjectInspectorListBox.WMMButtonUp(var Message: TWMMButtonDown);
begin
end;

procedure TGsvObjectInspectorListBox.CreateParams(
  var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // устанавливаем параметры дочернего окна, имеющего рамку и вертикальный
  // скроллинг
  Params.Style := WS_BORDER or WS_CHILD or WS_VSCROLL;
  // запрещаем уведомление родительского окна (его мы уберем после создания окна)
  // и разрешаем стиль WS_EX_TOOLWINDOW, чтобы окно списка не появлялось
  // в области таскбара
  Params.ExStyle := WS_EX_NOPARENTNOTIFY or WS_EX_TOOLWINDOW or WS_EX_TOPMOST;
  // сохраняем содержимое под списком, чтобы избежать перерисовки
  // подоконной области
  Params.WindowClass.Style := CS_SAVEBITS;
end;

procedure TGsvObjectInspectorListBox.CreateWnd;
begin
  inherited CreateWnd;
  // отсоединяем родительское окно, так как список будет выходить за его пределы.
  // Все эти манипуляции с окном приходится делать для того, чтобы окно
  // списка можно было бы закрыть щелчком мышки вне области списка.
  // Это редкая ситуация, которая возникает только в комбобоксах.
  // Разрешается она с помощью специального сообщения CM_CANCELMODE, которое
  // посылается при любом нажатии на кнопку мышки и может быть обработано
  // в окне редактора, чтобы скрыть окно списка
  Windows.SetParent(Handle, 0);
  // Используем умалчиваемую оконную процедуру для установки фокуса на окно
  // списка. Так как мы отсоединили родительское окно, то окно списка потом не
  // сможет получить фокус ввода. Фокус нужен нам, чтобы делать специальный вид
  // скроллинга списка, когда мышка перемещается вверх или вниз за пределами
  // окна при удерживании ее левой кнопки. Удобство этого вида скроллинга в
  // том, что скорость скроллинга определяется расстоянием курсора от окна списка
  CallWindowProc(DefWndProc, Handle, WM_SETFOCUS, 0, 0);
end;

procedure TGsvObjectInspectorListBox.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then begin
    if PtInRect(GetClientRect, Point(X, Y)) then
      HideList(True)
    else
      // мышь может быть за пределами окна из-за захвата (Capture) при нажатии
      // на левую кнопку в пределах окна, а отпускании за его пределами, например,
      // при скроллинге. В этом случае отвергаем выбор
      HideList(False);
  end;
end;


{ TGsvObjectInspectorInplaceEditor }

constructor TGsvObjectInspectorInplaceEditor.Create(AOwner: TComponent);
var
  w: Integer;
begin
  inherited Create(AOwner);
  FInspector := AOwner as TGsvCustomObjectInspectorGrid;
  // размер кнопки устанавливаем равным ширине скроллбара и убеждаемся, что
  // в эту ширину вместится изображение трех точек (для стиля pkDialog).
  // Стиль Dialog мы учитываем из-за того, что изображение треугольника
  // (для стилей выпадающего списка) имеет меньшую ширину
  FButtonWidth := GetSystemMetrics(SM_CXVSCROLL);
  w := BUTTON_POINT_SIZE * 7; // 7 = 3 точки + 2 промежутка + 2 отступа по краям
  if FButtonWidth < w then
    FButtonWidth := w;
  ParentColor      := False;
  ParentFont       := True;
 // Ctl3D            := False;
 // ParentCtl3D      := False;
  TabStop          := False;
  BorderStyle      := bsNone;
  DoubleBuffered   := False;
  AutoSelect       := False;
  AutoSize         := False;
  ShowHint         := False;
  FListBox         := TGsvObjectInspectorListBox.Create(Self);
  FListBox.Parent  := Self;
end;

// Установка текста с блокировкой сообщений о его изменении
procedure TGsvObjectInspectorInplaceEditor.SetNewEditText(const Value: String);
begin
  if Value = Text then begin
    Modified := False;
    Exit;
  end;
  FLockModify := True;
  try
    Text := Value;
  finally
    FLockModify := False;
  end;
  Modified := False;
end;

// Отображение окна редактора, метод вызывается инспектором
procedure TGsvObjectInspectorInplaceEditor.ShowEditor(
  ALeft, ATop, ARight, ABottom: Integer;
  Info: PGsvObjectInspectorPropertyInfo; const Value: String);
var
  r:  TRect;
  dy: Integer;
begin
  Assert(Assigned(Info));
  // обновление значения предыдущего измененного свойства
  if Modified and Assigned(FPropertyInfo) then
    FInspector.ValueChanged(FPropertyInfo, EditText);
  FLockModify := true;
  if Info.EditMask <> '' then begin
    if EditMask <> Info.EditMask then
      EditMask := Info.EditMask;
  end
  else
    EditMask := '';
  FLockModify := false;
  // установка нового значения свойства
  FPropertyInfo := Info;
  SetNewEditText(Value);
  // пересчет координат и размеров окна
  SetBounds(ALeft, ATop + 2, ARight - ALeft, ABottom - ATop - 3);
  dy := (((ABottom - ATop) - FInspector.FFontHeight) div 2) - 1;
  if dy < 0 then
    dy := 0;
  SetRect(r, VALUE_LEFT_MARGIN, dy, Width, Height);
  // если требуется кнопка, то уменьшаем размер области редактирования
  // и перемещаем каретку в видимую область
  if HAS(_BUTTON, FPropertyInfo) then
    Dec(r.Right, FButtonWidth);
  SendMessage(Handle, EM_SETRECTNP, 0, LongInt(@r));
  SendMessage(Handle, EM_SCROLLCARET, 0, 0);
  // изменяем цвет редактора в зависимости от того, доступно ли свойство
  // для редактирования или только для чтения
  if HAS(_READONLY, FPropertyInfo) then begin
    Color    := clBtnFace;
    ReadOnly := True;
  end
  else begin
    Color    := clWindow;
    ReadOnly := False;
    if FInspector.AutoSelect then
      SelectAll;
  end;
  if not FInspector.Visible then
    Exit;
  if not Visible then
    Visible := true;
  if Visible and Enabled and (not Focused) and FInspector.Focused then
    SetFocus;
  Invalidate;
end;

procedure TGsvObjectInspectorInplaceEditor.HideEditor;
begin
  if Focused and FInspector.Visible and FInspector.Enabled then
    FInspector.SetFocus;
  if Visible then
    Hide;
end;

// Отображение хинта редактируемой строки над окном редактора в процессе
// редактирования, если длина строки выходит за пределы редактора
procedure TGsvObjectInspectorInplaceEditor.ShowEditHint;
var
  r:  TRect;
  s:  String;
  w:  Integer;
  cw: Integer;
const
  TG = 2;
begin
  if not HAS(_READONLY, FPropertyInfo) then begin
    s := TextWithLimit(Text);
    w := FInspector.Canvas.TextWidth(s);
    cw := ClientWidth - 1;
    if HAS(_BUTTON, FPropertyInfo) then
      Dec(cw, FButtonWidth);
    if w > cw then begin
      r.Left   := Left - 1;
      r.Top    := Top - FInspector.FRowHeight - TG;
      r.Right  := Left + w + 4;
      r.Bottom := Top - TG;
      FInspector.ShowLongHint(r, s, True);
    end
    else
      FInspector.HideLongHint;
  end
  else
    FInspector.HideLongHint;
end;

// Отображение хинта значения длинного нередактируемого текста либо поверх
// редактора, либо слева от кнопки, если она есть
procedure TGsvObjectInspectorInplaceEditor.ShowValueHint;
var
  r:  TRect;
  s:  String;
  w:  Integer;
  cw: Integer;
  dw: Integer;
  bt: Boolean;
begin
  s  := TextWithLimit(Text);
  w  := FInspector.Canvas.TextWidth(s);
  cw := ClientWidth - 2;
  bt := HAS(_BUTTON, FPropertyInfo);
  if bt then
    Dec(cw, FButtonWidth);
  if w > cw then begin
    r.Left   := Left - 1;
    r.Top    := Top - 2;
    r.Right  := Left + w + 4;
    r.Bottom := r.Top + FInspector.FRowHeight;
    if bt then begin
      dw := FButtonWidth + (r.Right - r.Left) - Width - 1;
      Dec(r.Left, dw);
      Dec(r.Right, dw);
    end;
    FInspector.ShowLongHint(r, s);
  end
  else
    FInspector.HideLongHint;
end;

// Создание выпадающего списка
procedure TGsvObjectInspectorInplaceEditor.DropDown;

  function WorkAreaRect: TRect;
  begin
    SystemParametersInfo(SPI_GETWORKAREA, 0, @Result, 0);
  end;

var
  Org:   TPoint;   // экранные координаты окна редактора
  XList: Integer;  // левая координата списка
  YList: Integer;  // верхняя координата списка
  WList: Integer;  // ширина списка
  HList: Integer;  // высота списка
  RDesk: TRect;    // доступна область десктопа
  WDesk: Integer;  // ширина доступной области десктопа
  HDesk: Integer;  // высота доступной области десктопа
  i:     Integer;
  mw:    Integer;  // максимальная ширина строк списка
const
  HG = 2;
  YG = 2;
  XG = 2;
begin
  if FListBox.Visible then
    Exit;
  // очищаем список и заполняем его
  FListBox.Clear;
  FInspector.DoFillList(FPropertyInfo, FListBox.Items);
  if FListBox.Items.Count = 0 then
    Exit;
  // устанавливаем текущий элемент списка
  FListBox.ItemIndex := FListBox.Items.IndexOf(Text);
  Org := ClientOrigin;
  FListBox.ItemHeight := FInspector.FFontHeight;
  // корректируем число элемента окна
  FDropDownCount := FInspector.FDropDownCount;
  if FDropDownCount < 4 then
    FDropDownCount := 4;
  if FListBox.Items.Count < FDropDownCount then
    FDropDownCount := FListBox.Items.Count;
  // корректируем позицию списка
  RDesk := WorkAreaRect;
  HList := FListBox.ItemHeight * FDropDownCount + HG;
  YList := Org.Y + Height;
  if (YList + HList) > RDesk.Bottom then begin
    // недостаточно места для списка под редактором
    YList := Org.Y - HList - YG;
    if YList < RDesk.Top then begin
      HDesk := RDesk.Bottom - RDesk.Top;
      // недостаточно места для списка над редатором
      if Org.Y > (HDesk div 2) then begin
        // редактор расположен в нижней половине рабочей области десктопа,
        // размещаем список вверху и уменьшаем его размер
        FDropDownCount := ((Org.Y - RDesk.Top) div FListBox.ItemHeight) - 1;
        HList := FListBox.ItemHeight * FDropDownCount + HG;
        YList := Org.Y - HList - YG;
      end
      else begin
        // редактор расположен в верхней половине десктопа,
        // размещаем список внизу и уменьшаем его размер
        YList := Org.Y + Height;
        FDropDownCount := ((RDesk.Bottom - YList) div FListBox.ItemHeight) - 1;
        HList := FListBox.ItemHeight * FDropDownCount + HG;
      end;
    end;
  end;
  // вычисляем ширину строк списка
  mw := Width;
  for i := 0 to Pred(FListBox.Items.Count) do
    mw := Max(mw, FInspector.Canvas.TextWidth(FListBox.Items[i]));
  if mw > Width then begin
    // список шире, чем поле редактирования, корректируем его ширину и координаты
    WList := mw + 4;
    if FListBox.Items.Count > FDropDownCount then
      WList := WList + GetSystemMetrics(SM_CXVSCROLL);
    XList := Org.X + Width - WList;
    if XList < RDesk.Left then
      XList := RDesk.Left;
    WDesk := RDesk.Right - RDesk.Left;
    if (XList + WList) > WDesk then
      WList := WDesk - XList;
  end
  else begin
    XList := Org.X - XG;
    WList := Width + XG;
  end;
  // устанавливаем позицию и размеры окна списка и подготавливаем его к
  // отображению без передачи ему активности
  SetWindowPos(FListBox.Handle, 0, XList, YList, WList, HList, SWP_NOACTIVATE);
  FListBox.Visible := True;
  // устанавливаем фокус окна редактора, так как именно оно будет
  // делать все манипуляции со списком
  Windows.SetFocus(Handle);
end;

// Закрытие окна списка и прием значения (или отказ от приема, если
// значение Accept будет ложным)
procedure TGsvObjectInspectorInplaceEditor.CloseUp(Accept: Boolean);
var
  i: Integer;
begin
  Assert(Assigned(FListBox));
  if FListBox.Visible then begin
    // если разрешен прием значения, то передаем строку выбранного
    // элемента списка для фиксации ее значения в инспектируемом объекте
    i := FListBox.ItemIndex;
    if Accept and (i >= 0) then
      FInspector.ValueChanged(FPropertyInfo, FListBox.Items[i]);
    // получаем реальное значение установленного свойства
    SetNewEditText(FInspector.DoGetStringValue(FPropertyInfo));
    // запрещаем появление хинта на пару секунд после закрытия списка
    FInspector.HideLongHint(True);
    // скрываем и очищаем список
    FListBox.Hide;
    FListBox.Clear;
  end;
end;

// Отображение значения текущего элемента списка строк
procedure TGsvObjectInspectorInplaceEditor.ListItemChanged;
begin
  Assert(Assigned(FListBox));
  Text := FListBox.Items[FListBox.ItemIndex];
end;

// Прямая навигация по списку строк
procedure TGsvObjectInspectorInplaceEditor.SetListItem(Index: Integer);
var
  d: Integer;
begin
  Assert(Assigned(FListBox));
  if Index >= FListBox.Items.Count then
    Index := FListBox.Items.Count - 1;
  if Index < 0 then
    Index := 0;
  if Index >= FListBox.Items.Count then
    Exit;
  d := FListBox.TopIndex;
  if Index < d then
    d := Index
  else if (d + FDropDownCount - 1) >= Index then
    d := Index - FDropDownCount + 1;
  if FListBox.TopIndex <> d then
    FListBox.TopIndex := d;
  if FListBox.ItemIndex <> Index then
    FListBox.ItemIndex := Index;
  ListItemChanged;
end;

// Вызов диалога-мастера
procedure TGsvObjectInspectorInplaceEditor.ShowDialog;
begin
  if FListBox.Visible then
    Exit;
  if Modified and Assigned(FPropertyInfo) then begin
    FInspector.ValueChanged(FPropertyInfo, Text);
    SetNewEditText(FInspector.DoGetStringValue(FPropertyInfo));
  end;
  FInspector.DoShowDialog;
end;

procedure TGsvObjectInspectorInplaceEditor.ValidateStringValue(
  const Value: String);
var
  s: string;
  p: Integer;
begin
  if IsMasked then begin
    s := EditText;
    if not TryStrToInt(s, p) then
      raise EDBEditError.CreateRes(@SMaskErr);
  end;
end;

// Закрытие списка при нажатии кнопки мышки за пределами списка
procedure TGsvObjectInspectorInplaceEditor.CMCancelMode(
  var Message: TLMessage);
begin
 // if (Message.Sender <> Self) and (Message.Sender <> FListBox) then
  case message.msg of
    LM_NCHITTEST  :CloseUp(False);
end;
end;

// Разрешение перерисовки области стандартного окна редактирования
procedure TGsvObjectInspectorInplaceEditor.WMPaint(var Message: TLMPaint);
begin
  PaintHandler(Message);
end;

// Установка курсора мыши в зависимости от того, где он находится -
// в поле редактирования или на кнопке
procedure TGsvObjectInspectorInplaceEditor.WMSetCursor(
  var Message: TWMSetCursor);
var
  p:   TPoint;
  r:   TRect;
  inh: Boolean;
begin
  inh := True;
  if HAS(_BUTTON, FPropertyInfo) then begin
    GetCursorPos(p);
    SetRect(r, Width - FButtonWidth, 0, Width, Height);
    if PtInRect(r, ScreenToClient(p)) then begin
      Windows.SetCursor(LoadCursor(0, IDC_ARROW));
      inh := False;
    end;
  end;
  if inh then
    inherited;
end;

// Используются обработчики событий Windows (раннее обнаружение события)
// из-за того, что требуется различное поведение в зависимости от места, где
// нажата клавиша мышки - на поле редактирования или на кнопке
procedure TGsvObjectInspectorInplaceEditor.WMLButtonDown(
  var Message: TWMLButtonDown);
var
  r:   TRect;
  inh: Boolean;
  inv: Boolean;
  sl:  Boolean;
begin
 // SendCancelMode(Self);
  MouseCapture := True;
  ControlState := ControlState + [csClicked];
  inh := True;
  inv := False;
  sl  := False;
  if HAS(_BUTTON, FPropertyInfo) then begin
    SetRect(r, Width - FButtonWidth, 0, Width, Height);
    if PtInRect(r, Point(Message.XPos, Message.YPos)) then begin
      FPressed    := True;
      FWasPressed := True;
      inh         := False;
      inv         := True;
      sl          := HAS(_LIST, FPropertyInfo);
    end;
  end;
  if inh then
    inherited;
  if inv then
    Invalidate;
  if FListBox.Visible then
    CloseUp(False)
  else if sl then
    DropDown;
end;

procedure TGsvObjectInspectorInplaceEditor.WMLButtonUp(
  var Message: TWMLButtonUp);
var
  inv: Boolean;
  sw:  Boolean;
begin
  MouseCapture := False;
  ControlState := ControlState - [csClicked];
  inv := False;
  sw  := False;
  if FWasPressed then begin
    FWasPressed := False;
    FPressed    := False;
    inv         := True;
    sw          := HAS(_DIALOG, FPropertyInfo);
  end
  else
    inherited;
  if inv then
    Invalidate;
  if sw then
    ShowDialog;
end;

// Перехват и игнорирование двойного нажатия, если оно сделано на кнопке
procedure TGsvObjectInspectorInplaceEditor.WMLButtonDblClk(
  var Message: TWMLButtonDblClk);
var
  r:        TRect;
  InButton: Boolean;
begin
 // SendCancelMode(Self);
  InButton := False;
  if HAS(_BUTTON, FPropertyInfo) then begin
    SetRect(r, Width - FButtonWidth, 0, Width, Height);
    InButton := PtInRect(r, Point(Message.XPos, Message.YPos));
  end;
  if not InButton then begin
    if not ReadOnly then
      // выделение всего текста вместо стандартной реакции выделения слова.
      // Выделение слова - это стандартная реакция режиме многострочного редактора
      SelectAll
    else if HAS(_LIST, FPropertyInfo) then
      DropDown
    else if HAS(_DIALOG, FPropertyInfo) then
      ShowDialog;
  end;
end;

procedure TGsvObjectInspectorInplaceEditor.WMKillFocus(
  var Message: TMessage);
begin
  inherited;
  CloseUp(False);
end;

procedure TGsvObjectInspectorInplaceEditor.CreateParams(
  var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // дополнительно к обычным стилям добавляем стиль многострочного редактора
  // для того, чтобы можно было ограничить область редактирования
  // и нарисовать кнопку в правой части области элемента редактирования
  Params.Style := Params.Style or ES_MULTILINE;
end;

procedure TGsvObjectInspectorInplaceEditor.CreateWnd;
begin
  inherited CreateWnd;
  // мы присвоили Parent для окна списка в конструкторе, когда
  // окно еще не было полностью создано и не был выделен Windows-описатель.
  // Теперь, после окончательного создания окна редактора нужно завершить
  // создание окна списка
  if Assigned(FListBox) then
    FListBox.HandleNeeded;
end;

// Рисование кнопки, если она есть
procedure TGsvObjectInspectorInplaceEditor.PaintWindow(DC: HDC);
var
  r:     TRect;
  Flags: Integer;
  x, y:  Integer;
  w:     Integer;
  ew:    Integer;
begin
  ew := Width;
  if HAS(_BUTTON, FPropertyInfo) then begin
    ew := ew - FButtonWidth;
    SetRect(r, ew, 0, Width, Height);
    // отрисовка обычной кнопки. Если она нажата, то используется плоский стиль
    if FPressed then
      Flags := BF_FLAT or DFCS_PUSHED
    else
      Flags := 0;
    DrawFrameControl(DC, r, DFC_BUTTON, Flags or DFCS_BUTTONPUSH);
    if HAS(_DIALOG, FPropertyInfo) then begin
      // отрисовка трех точек - графического образа мастера
      x := r.Left + FButtonWidth div 2 - BUTTON_POINT_SIZE div 2;
      y := r.Top  + Height div 2 - BUTTON_POINT_SIZE div 2;
      // при нажатой кнопке сдвигаем образ вправо и вниз
      if FPressed then begin
        Inc(x);
        Inc(y);
      end;
      PatBlt(DC, x, y, BUTTON_POINT_SIZE, BUTTON_POINT_SIZE, BLACKNESS);
      PatBlt(DC, x - BUTTON_POINT_SIZE * 2, y, BUTTON_POINT_SIZE,
        BUTTON_POINT_SIZE, BLACKNESS);
      PatBlt(DC, x + BUTTON_POINT_SIZE * 2, y, BUTTON_POINT_SIZE,
        BUTTON_POINT_SIZE, BLACKNESS);
    end
    else begin
      // отрисовка треугольника - графического образа выпадающего списка
      w := BUTTON_POINT_SIZE * 3 + 1;
      x := r.Left + (FButtonWidth - w) div 2;
      y := r.Top + (Height - w div 2) div 2;
      if FPressed then begin
        Inc(x);
        Inc(y);
      end;
      // рисуем треугольник линиями одиночной высоты, начиная с верхней линии,
      // каждый раз уменьшая ширину линии
      while w > 0 do begin
        PatBlt(DC, x, y, w, 1, BLACKNESS);
        Inc(x);
        Inc(y);
        Dec(w, 2);
      end;
    end;
  end;
  inherited PaintWindow(DC);
end;

// Изменение значения свойства при потере фокуса
procedure TGsvObjectInspectorInplaceEditor.DoExit;
begin
  inherited;
  FInspector.HideLongHint;
  if Modified then begin
    try
      FInspector.ValueChanged(FPropertyInfo, EditText);
    except
    end;
    Modified := False;
  end;
end;

// Реакция на перемещение мышки, чтобы изменять вид курсора при нажатой кнопке
// и вызывать отображение хинта при длинной строке значения
procedure TGsvObjectInspectorInplaceEditor.MouseMove(Shift: TShiftState; X,
  Y: Integer);
var
  r: TRect;
  p: Boolean;
begin
  inherited;
  if FWasPressed then begin
    SetRect(r, Width - FButtonWidth, 0, Width, Height);
    p := PtInRect(r, Point(x, y));
    if p <> FPressed then begin
      FPressed := p;
      Invalidate;
    end;
  end
  else
    ShowValueHint;
end;

// Следующие несколько функций служат для навигации по инспектируемым свойствам
// или по строкам выпадающего списка в зависимости от того, виден список или нет

// Навигация с помощью мышиного колеса
function TGsvObjectInspectorInplaceEditor.DoMouseWheelDown(
  Shift: TShiftState; MousePos: TPoint): Boolean;
var
  h: Integer;
  c: Integer;
  t: Integer;
  i: Integer;
begin
  if FListBox.Visible then begin
    c := FListBox.Items.Count;
    h := FInspector.FDropDownCount;
    if c > h then begin
      t := FListBox.TopIndex;
      // пытаемся прокрутить список вперед на видимое число элементов минус 1
      Inc(t, h - 1);
      if (t + h) >= c then begin
        t := c - h + 1;
        i := c - 1;
      end
      else
        i := t;
      if t <> FListBox.TopIndex then
        FListBox.TopIndex := t;
      if i <> FListBox.ItemIndex then
        FListBox.ItemIndex := i;
      ListItemChanged;
    end;
    Result := True;
  end
  else begin
    // иначе сообщение считается необработанным и передается родительскому окну,
    // то есть, инспектору
    Result := False;
    // кроме того, при навигации скрываем хинт длинной строки
    FInspector.HideLongHint(True);
  end;
end;

function TGsvObjectInspectorInplaceEditor.DoMouseWheelUp(
  Shift: TShiftState; MousePos: TPoint): Boolean;
var
  h: Integer;
  t: Integer;
  i: Integer;
begin
  if FListBox.Visible then begin
    t := FListBox.TopIndex;
    i := FListBox.ItemIndex;
    if (t <> 0) or (i <> 0) then begin
      h := FInspector.FDropDownCount;
      if t <> 0 then begin
        Dec(t, h - 1);
        if t < 0 then begin
          t := 0;
          i := 0;
        end
        else
          i := t;
      end
      else
        i := 0;
      if t <> FListBox.TopIndex then
        FListBox.TopIndex := t;
      if i <> FListBox.ItemIndex then
        FListBox.ItemIndex := i;
      ListItemChanged;
    end;
    Result := True;
  end
  else begin
    Result := False;
    FInspector.HideLongHint(True);
  end;
end;

// Навигация с помощью клавиатуры
procedure TGsvObjectInspectorInplaceEditor.KeyDown(var Key: Word;
  Shift: TShiftState);
var
  i:      Integer;
  NoList: Boolean;
begin
  NoList := True;
  if Assigned(FListBox) then begin
    if FListBox.Visible then begin
      // перемещение по списку
      i := FListBox.ItemIndex;
      case Key of
        VK_DOWN:   SetListItem(i + 1);
        VK_UP:     SetListItem(i - 1);
        VK_NEXT:   SetListItem(i + FDropDownCount - 1);
        VK_PRIOR:  SetListItem(i - FDropDownCount + 1);
        VK_HOME:   SetListItem(0);
        VK_END:    SetListItem(FListBox.Items.Count - 1);
        VK_ESCAPE: CloseUp(False);
        VK_RETURN: CloseUp(True);
      end;
      Key    := 0;
      NoList := False;
    end
  end;
  if NoList then begin
    if (ssAlt in Shift) and (Key = VK_DOWN) then begin
      // реализация стандартной комбинации комбобокса: Alt + Down
      Key := 0;
      if HAS(_DIALOG, FPropertyInfo) then
        ShowDialog
      else begin
        NoList := True;
        DropDown;
      end;
    end;
  end;
  if NoList then begin
    // перемещение по инспектируемым свойствам
    case Key of
      VK_DOWN, VK_UP, VK_PRIOR, VK_NEXT:
      begin
        FInspector.SetSelectedRowByKey(Key);
        Key := 0;
      end;
      VK_HOME, VK_END:
      begin
        if ssCtrl in Shift then begin
          FInspector.SetSelectedRowByKey(Key);
          Key := 0;
        end;
      end;
      VK_ESCAPE, VK_RETURN: Key := 0;
      VK_LEFT, VK_SUBTRACT, VK_OEM_MINUS:
      begin
        if Assigned(FPropertyInfo) then begin
          if FPropertyInfo.Kind = pkSet then begin
            FInspector.ExpandingOrChangeBoolean(True, tctCollapse);
            Key := 0;
          end;
        end;
      end;
      VK_RIGHT, VK_ADD, VK_OEM_PLUS:
      begin
        if Assigned(FPropertyInfo) then begin
          if FPropertyInfo.Kind = pkSet then begin
            FInspector.ExpandingOrChangeBoolean(True, tctExpand);
            Key := 0;
          end;
        end;
      end;
    end;
  end;
  inherited;
  // при навигации скрываем хинт длинной строки, при других клавишах
  // отображаем хинт редактирования, если он нужен
  if Key = 0 then
    FInspector.HideLongHint(True)
  else
    ShowEditHint;
end;

// Изменение значения свойства при нажатии клавиши Enter
procedure TGsvObjectInspectorInplaceEditor.KeyPress(var Key: Char);
begin
  if Key = #13 then begin
    if HAS(_INPUT_TEXT, FPropertyInfo) then begin
      // изменение значения свойства
      FInspector.ValueChanged(FPropertyInfo, EditText);
      // сброс признака измененности и переустановка нового значения на
      // тот случай, если изменения были отвергнуты как неправильные,
      // например, при вводе числа были введены буквы
      SetNewEditText(FInspector.DoGetStringValue(FPropertyInfo));
    end
    else if HAS(_DIALOG, FPropertyInfo) then
      ShowDialog
    else if FPropertyInfo.Kind = pkSet then
      FInspector.ExpandingOrChangeBoolean(True, tctChange);
    // не позволяем коду перевода строки попасть в редактируемый текст
    Key := #0;
  end
  else if Key = #32 then begin
    if FPropertyInfo.Kind = pkSet then begin
      FInspector.ExpandingOrChangeBoolean(True, tctChange);
      Key := #0;
    end;
  end;
  inherited;
end;

procedure TGsvObjectInspectorInplaceEditor.KeyUp(var Key: Word;
  Shift: TShiftState);
var
  NoList: Boolean;
begin
  NoList := True;
  if Assigned(FListBox) then begin
    if FListBox.Visible then begin
      NoList := False;
      Key    := 0;
    end;
  end;
  if NoList then begin
    case Key of
      VK_DOWN, VK_UP, VK_PRIOR, VK_NEXT, VK_ESCAPE, VK_RETURN: Key := 0;
      VK_F1: FInspector.DoHelp;
    end;
  end;
  inherited;
end;

// Обработка изменения текста по любой причине
procedure TGsvObjectInspectorInplaceEditor.Change;
begin
  inherited;
  // если установлена блокировка, то игнорируем изменения. Блокировка
  // выполняется, когда редактор получает новое строковое значение,
  // после чего сбрасывается признак модицикации текста и выполняется
  // разблокировка
  if FLockModify then
    Exit;
  if Assigned(FPropertyInfo) then begin
    if FPropertyInfo^.Kind = pkImmediateText then begin
      // немедленное изменение значения свойства объекта
      FInspector.ValueChanged(FPropertyInfo, EditText);
      // поскольку изменение зафиксировано, сбрасываем признак модификации
      Modified := False;
    end;
  end;
  // показывем хинт длинной строки (если это нужно)
  ShowEditHint;
end;

procedure TGsvObjectInspectorInplaceEditor.ValidateError;
begin
end;

procedure TGsvObjectInspectorInplaceEditor.ValidateEdit;
begin
end;

{ TGsvCustomObjectInspectorGrid }

constructor TGsvCustomObjectInspectorGrid.Create(AOwner: TComponent);
const
  st = [csCaptureMouse, csOpaque, csClickEvents, csDoubleClicks, csNeedsBorderPaint];
begin
  // первоначальный размер массива видимых свойств
  SetLength(FRows, PROP_LIST_DELTA);
  FProperties := TGsvObjectInspectorProperties.Create(Self);
  FGlyphs     := TBitmap.Create;
  //FGlyphs.LoadFromResourceName(HInstance, 'GSVOBJECTINSPECTORGLYPHS');

  FMouseDivPos       := -1;
  FFontHeight        := 13;
  FLevelIndent       := GLYPH_MAGRIN * 2 + GLYPH_TREE_SIZE;

  FRowHeight         := 18;
  FDividerPosition   := 100;
  FFolderFontColor   := clBtnText;
  FFolderFontStyle   := [fsBold];
  FLongTextHintTime  := 3000;
  FLongEditHintTime  := 3000;
  FAutoSelect        := True;
  FMaxTextLength     := 256;
  FDropDownCount     := 8;
  FHideReadOnly      := False;

  inherited Create(AOwner);
  if NewStyleControls then
    ControlStyle := st
  else
    ControlStyle := st + [csFramed];
  Width          := 200;
  Height         := 100;
  DoubleBuffered := True;
  ShowHint       := False;
  ParentColor    := False;
  Color          := clBtnFace;
  Font.Color     := clBtnText;
  FBorderStyle   := bsSingle;
end;

destructor TGsvCustomObjectInspectorGrid.Destroy;
begin
  FRows := nil;
  FProperties.Free;
  FGlyphs.Free;
  inherited Destroy;
end;

procedure TGsvCustomObjectInspectorGrid.SetBorderStyle(
  const Value: TBorderStyle);
begin
  if Value <> FBorderStyle then begin
    FBorderStyle := Value;
    RecreateWnd(self);
  end;
end;

procedure TGsvCustomObjectInspectorGrid.SetRowHeight(const Value: Integer);
begin
  if (FRowHeight <> Value) and (Value >= 12) then begin
    FRowHeight := Value;
    UpdateScrollBar;
    Invalidate;
  end;
end;

// Изменение позиции линии разделителя с учетом ограничений
procedure TGsvCustomObjectInspectorGrid.SetDividerPosition(
  const Value: Integer);
begin
  if (FDividerPosition <> Value) and (Value >= DIVIDER_LIMIT) and
    (Value < (ClientWidth - DIVIDER_LIMIT)) then
  begin
    FDividerPosition := Value;
    Invalidate;
  end;
end;

procedure TGsvCustomObjectInspectorGrid.SetFolderFontColor(
  const Value: TColor);
begin
  if FFolderFontColor <> Value then begin
    FFolderFontColor := Value;
    Invalidate;
  end;
end;

procedure TGsvCustomObjectInspectorGrid.SetFolderFontStyle(
  const Value: TFontStyles);
begin
  if FFolderFontStyle <> Value then begin
    FFolderFontStyle := Value;
    Invalidate;
  end;
end;

procedure TGsvCustomObjectInspectorGrid.SetLongTextHintTime(
  const Value: Cardinal);
begin
  if FLongTextHintTime <> Value then begin
    FLongTextHintTime := Value;
    HideLongHint;
    if (FLongTextHintTime = 0) and (FLongEditHintTime = 0) and
        Assigned(FHintWindow) then
    begin
      // уничтожаем окно хинта, если оно не нужно
      FHintWindow.Free;
      FHintWindow := nil;
    end;
  end;
end;

procedure TGsvCustomObjectInspectorGrid.SetLongEditHintTime(
  const Value: Cardinal);
begin
  if FLongEditHintTime <> Value then begin
    FLongEditHintTime := Value;
    HideLongHint;
    if (FLongTextHintTime = 0) and (FLongEditHintTime = 0) and
        Assigned(FHintWindow) then
    begin
      FHintWindow.Free;
      FHintWindow := nil;
    end;
  end;
end;

procedure TGsvCustomObjectInspectorGrid.SetMaxTextLength(
  const Value: Integer);
begin
  if FMaxTextLength <> Value then begin
    FMaxTextLength := Value;
    if Assigned(FEditor) then
      FEditor.MaxLength := FMaxTextLength;
  end;
end;

procedure TGsvCustomObjectInspectorGrid.SetHideReadOnly(
  const Value: Boolean);
begin
  if FHideReadOnly <> Value then begin
    FHideReadOnly := Value;
    NewObject;
  end;
end;

function TGsvCustomObjectInspectorGrid.GetLayout: string;
var
  h:  TGsvObjectInspectorHistory;
  hn: string;
begin
  Result := '';
  hn := FProperties.HistoryName;
  if hn <> '' then begin
    h := TGsvObjectInspectorHistory.Create;
    try
      FProperties.FillHistory(h);
      Result := h.ToString(hn);
    finally
      h.Free;
    end;
  end;
end;

procedure TGsvCustomObjectInspectorGrid.SetLayout(const Value: string);
var
  t, s: Integer;
begin
  if FProperties.SetLayout(Value, t, s) then begin
    CreateRows;
    FTopRow   := t;
    FSelected := -1;
    UpdateScrollBar;
    SetSelectedRow(s);
  end;
end;

procedure TGsvCustomObjectInspectorGrid.CMCtl3DChanged(var Message: TMessage);
begin
  inherited;
  if NewStyleControls and (FBorderStyle = bsSingle) then
    RecreateWnd(self);
end;

// Обработка событий от вертикального скроллинга - они приводят к
// изменению индекса верхнего отображаемого свойства, но не изменяют
// выделенного свойства
procedure TGsvCustomObjectInspectorGrid.WMVScroll(var Msg: TWMVScroll);
var
  rc: Integer;
  si: Windows.TScrollInfo;
begin
  inherited;
  rc := ClientHeight div FRowHeight;
  with Msg do begin
    case ScrollCode of
      SB_LINEUP:   SetTopRow(FTopRow - 1);
      SB_LINEDOWN: SetTopRow(FTopRow + 1);
      SB_PAGEUP:   SetTopRow(FTopRow - rc);
      SB_PAGEDOWN: SetTopRow(FTopRow + rc);
      SB_THUMBPOSITION, SB_THUMBTRACK:
      begin
        si.cbSize := SizeOf(TScrollInfo);
        SI.fMask  := SIF_TRACKPOS;
        if GetScrollInfo(Handle, SB_VERT, si) then
          SetTopRow(si.nTrackPos);
      end;
    end;
  end;
end;

// Разрешает реакцию на кнопки вверх-вниз
procedure TGsvCustomObjectInspectorGrid.WMGetDlgCode(
  var Msg: TWMGetDlgCode);
begin
  inherited;
  Msg.Result := DLGC_WANTARROWS;
end;

// Если мышь покидает область инспектора, то сбрасываем хинт (если он есть)
procedure TGsvCustomObjectInspectorGrid.CMMouseLeave(
  var Message: TMessage);
begin
  inherited;
  HideLongHint;
end;

procedure TGsvCustomObjectInspectorGrid.WMShowDialog(
  var Message: TMessage);
var
  r: TRect;
  p: TPoint;
begin
  if csDesigning in ComponentState then
    Exit;
  if not FEditor.Visible then
    Exit;
  if not Assigned(FEditor.FPropertyInfo) then
    Exit;
  if not Assigned(FOnShowDialog) then
    Exit;
  r := FEditor.ClientRect;
  p := FEditor.ClientOrigin;
  OffsetRect(r, p.X, p.Y);
  FOnShowDialog(Self, FEditor.FPropertyInfo, r);
  Invalidate;
  ShowEditor;
end;

procedure TGsvCustomObjectInspectorGrid.WMHelp(var aMessage: TMessage);
var
  hi: PHELPINFO;
  pt: TPoint;
  r:  Integer;
begin
  if not Assigned(FOnHelp) then
    Exit;
  hi := PHELPINFO(aMessage.LParam);
  pt := ScreenToClient(hi.MousePos);
  r  := FTopRow + (pt.Y div FRowHeight);
  if (r >= 0) and (r <= High(FRows)) then begin
    if FRows[r].Help <> 0 then
      FOnHelp(Self, FRows[r]);
  end;
end;

// Тест нахождения мыши в пределах линии разделителя
function TGsvCustomObjectInspectorGrid.DividerHitTest(X: Integer): Boolean;
const
  G = 2;
begin
  Result := (X >= (FDividerPosition - G)) and (X <= (FDividerPosition + G));
end;

// Создание списка всех свойств объекта
procedure TGsvCustomObjectInspectorGrid.EnumProperties;
var
  p:     PGsvObjectInspectorPropertyInfo;
  Index: Integer;
begin
  HideLongHint;
  HideEditor;
  FProperties.Clear;
  Index := 0;
  if Assigned(FOnEnumProperties) then begin
    FOnEnumProperties(Self, Index, p);
    while Assigned(p) do begin
      FProperties.Add(p);
      Inc(Index);
      FOnEnumProperties(Self, Index, p);
    end;
  end;
  // создаем список отображаемых свойств
  CreateRows;
  FTopRow   := FProperties.TopRow;
  FSelected := -1;
  UpdateScrollBar;
  if FRowsCount <> 0 then
    SetSelectedRow(FProperties.Selected)
  else
    Invalidate;
end;

// Создание списка отображаемых свойств на основе полного списка в зависимости
// от значений Expanded
procedure TGsvCustomObjectInspectorGrid.CreateRows;
var
  i: Integer;

  // добавление свойства
  procedure AddRow(p: PGsvObjectInspectorPropertyInfo);
  begin
    Assert(Assigned(p));
    // пропускаем свойства по чтению если не задан флаг отображения всех свойств
    if FHideReadOnly and (p^.Kind = pkReadOnlyText) then
      Exit;
    if FRowsCount > High(FRows) then
      SetLength(FRows, Length(FRows) + PROP_LIST_DELTA);
    FRows[FRowsCount] := p;
    Inc(FRowsCount);
  end;

  // пропуск уровня и всех его поуровней
  procedure SkipLevel(ALevel: Integer);
  begin
    while i < FProperties.Count do begin
      if FProperties[i]^.Level >= ALevel then
        Inc(i)
      else
        Break;
    end;
  end;

  // рекурсивное заполнение одного уровня древовидной структуры свойств
  procedure FillLevel(ALevel: Integer);
  var
    p: PGsvObjectInspectorPropertyInfo;
  begin
    while i < FProperties.Count do begin
      p := FProperties[i];
      if p^.Level = ALevel then begin
        AddRow(p);
        if p^.HasChildren then begin
          if p^.Expanded then begin
            Inc(i);
            FillLevel(ALevel + 1);
          end
          else begin
            Inc(i);
            SkipLevel(ALevel + 1);
          end
        end
        else
          Inc(i);
      end
      else
        Break;
    end;
  end;

begin
  FRowsCount := 0;
  i          := 0;
  FillLevel(0);
end;

// Обновление свойств полоски вертикального скроллинга в
// зависимости от числа отображаемых свойств и установка ее параметров
procedure TGsvCustomObjectInspectorGrid.UpdateScrollBar;
var
  si: Windows.TScrollInfo;
  rc: Integer;
begin
  if not HandleAllocated then
    Exit;
  rc := ClientHeight div FRowHeight;
  si.cbSize := SizeOf(si);
  si.fMask  := SIF_PAGE or SIF_POS or SIF_RANGE;
  si.nMin   := 0;
  if (FRowsCount <= rc) then si.nMax := 0
  else                       si.nMax := FRowsCount;
  if si.nMax <> 0 then si.nPage := rc + 1
  else                 si.nPage := 0;
  if (si.nMax <> 0) and (FTopRow > 0) then begin
    si.nPos      := FTopRow;
    si.nTrackPos := FTopRow;
  end
  else begin
    if (si.nMax = 0) and (FTopRow <> 0) then
      FTopRow := 0;
    si.nPos      := 0;
    si.nTrackPos := 0;
  end;
  SetScrollInfo(Handle, SB_VERT, si, True);
end;

// Отображение окна подсказки для длинной строки
procedure TGsvCustomObjectInspectorGrid.ShowLongHint(const Rect: TRect;
  const AText: String; IsEditHint: Boolean);
begin
  // запрещаем в режиме проектирования
  if csDesigning in ComponentState then
    Exit;
  // запрещаем, если не задано время отображения
  if (not IsEditHint) and (FLongTextHintTime = 0) then
    Exit;
  if IsEditHint and (FLongEditHintTime = 0) then
    Exit;
  // создаем окно хинта (если его еще нет)
  if not Assigned(FHintWindow) then begin
    if not HandleAllocated then
      Exit;
    FHintWindow := TGsvObjectInspectorHintWindow.Create(Self)
  end;
  // вызываем процедуру отображения хинта
  FHintWindow.ActivateHint(Rect, AText, IsEditHint);
end;

// Скрытие окна подсказки
procedure TGsvCustomObjectInspectorGrid.HideLongHint(HardHide: Boolean);
begin
  if Assigned(FHintWindow) then
    FHintWindow.HideLongHint(HardHide);
end;

// Отображение окна редактора если он нужен или скрытие его, если не нужен
procedure TGsvCustomObjectInspectorGrid.ShowEditor;
var
  y0: Integer;
begin
  // недоступно при проектировании
  if csDesigning in ComponentState then
    Exit;
  if (FRowsCount = 0) or (FTopRow < 0) or
     (FSelected < 0) or (FSelected >= FRowsCount) then
  begin
    HideEditor;
    Exit;
  end;
  // создаем окно, если его еще нет
  if not Assigned(FEditor) then begin
    if not HandleAllocated then
      Exit;
    FEditor           := TGsvObjectInspectorInplaceEditor.Create(Self);
    FEditor.Parent    := Self;
    FEditor.MaxLength := FMaxTextLength;
  end;
  // если выделенное свойство требует окна редактора, то показываем его
  // и передаем ему фокус ввода
  if HAS(_EDITOR, FRows[FSelected]) then begin
    y0 := (FSelected - FTopRow) * FRowHeight;
    FEditor.ShowEditor(FDividerPosition + 2, y0, ClientWidth, y0 + FRowHeight,
      FRows[FSelected], DoGetStringValue(FRows[FSelected]));
    UpdateFocus;
  end
  else
    HideEditor;
end;

// Скрытие окна редактора
procedure TGsvCustomObjectInspectorGrid.HideEditor;
begin
  if Assigned(FEditor) then
    FEditor.HideEditor;
end;

// Обновление текста в видимом поле редактирования без изменения фокуса
procedure TGsvCustomObjectInspectorGrid.UpdateEditor;
begin
  if not Assigned(FEditor) then
    Exit;
  if not FEditor.Visible then
    Exit;
  if FEditor.Modified then
    Exit;
  if (FRowsCount = 0) or (FTopRow < 0) or
     (FSelected < 0) or (FSelected >= FRowsCount) then
    Exit;
  FEditor.SetNewEditText(DoGetStringValue(FRows[FSelected]));
end;

// Коррекция фокуса ввода
procedure TGsvCustomObjectInspectorGrid.UpdateFocus;
begin
  if Visible and Enabled then
    if Assigned(FEditor) then
      if FEditor.Visible and FEditor.Enabled and Focused and (not FEditor.Focused) then
        FEditor.SetFocus;
end;

// Установка нового верхнего отображаемого свойства
procedure TGsvCustomObjectInspectorGrid.SetTopRow(ATopRow: Integer);
var
  rc, d: Integer;
begin
  HideLongHint;
  if (FRowsCount = 0) or (ATopRow < 0) then
    Exit;
  rc := ClientHeight div FRowHeight;
  d  := FRowsCount - rc;
  if ATopRow > d then
    ATopRow := d;
  if ATopRow < 0 then
    ATopRow := 0;
  if FTopRow = ATopRow then begin
    UpdateFocus;
    Exit;
  end;
  FTopRow := ATopRow;
  HideEditor;
  UpdateScrollBar;
  Invalidate;
  ShowEditor;
end;

// Установка нового выделенного свойства
procedure TGsvCustomObjectInspectorGrid.SetSelectedRow(ARow: Integer);
var
  rc:             Integer;
  tr:             Integer;
  NeedInvalidate: Boolean;
begin
  HideLongHint;
  if FRowsCount = 0 then
    Exit;
  if ARow >= FRowsCount then
    ARow := FRowsCount - 1;
  if ARow < 0 then
    ARow := 0;
  DoHint(FRows[ARow]);
  if FSelected = ARow then begin
    UpdateFocus;
    Exit;
  end;
  FSelected      := ARow;
  rc             := ClientHeight div FRowHeight;
  NeedInvalidate := True;
  // начальная установка верхнего отображаемого свойства
  if FTopRow < 0 then
    SetTopRow(FSelected);
  if FSelected < FTopRow then begin
    // выделенное свойство не видно - перерисовка не требуется
    SetTopRow(FSelected);
    NeedInvalidate := False;
  end
  else if FSelected >= (FTopRow + rc) then begin
    tr := FTopRow;
    SetTopRow(FSelected - rc + 1);
    // устанавливаем признак перерисовки если выделенное свойство видимо
    NeedInvalidate := (tr = FTopRow);
  end;
  if not NeedInvalidate then begin
    UpdateFocus;
    Exit;
  end;
  // отображение редактора для нового выделенного свойства
  HideEditor;
  Invalidate;
  ShowEditor;
  UpdateFocus;
end;

// Выделение свойства исходя из координаты мыши
procedure TGsvCustomObjectInspectorGrid.SetSelectedRowByMouse(X, Y: Integer);
var
  sr: Integer;
begin
  if (X < 0) or (X > ClientWidth) then
    Exit;
  sr := FSelected;
  // выделение свойства
  SetSelectedRow(FTopRow + (Y div FRowHeight));
  // если выделяется уже выделенное свойство, то выполняется
  // расширение или свертывание подсвойств нижнего уровня или
  // изменяется значение поля типа pkBoolean на противоположное
  if sr = FSelected then
    ExpandingOrChangeBoolean(X < FDividerPosition, tctChange);
end;

// Изменение логического значения свойства типа Boolean или элемента
// множества на противоположное
procedure TGsvCustomObjectInspectorGrid.ChangeBoolean(
  Info: PGsvObjectInspectorPropertyInfo);
var
  OrdVal:  LongInt; // порядковое значение логической величины
begin
  Assert(Assigned(Info));
  OrdVal := DoGetIntegerValue(Info);
  DoSetIntegerValue(Info, GsvChangeBit(OrdVal, Info^.Tag));
end;

// Изменение списка отображаемых свойств при изменении значения Expanded
// текущего свойства или изменение значения поля типа pkBoolean на
// противоположное
procedure TGsvCustomObjectInspectorGrid.ExpandingOrChangeBoolean(
  ExpandingOnly: Boolean; ChangeType: TGsvObjectInspectorTreeChangeType);
var
  p:   PGsvObjectInspectorPropertyInfo;
  pcw: Integer;
  e:   Boolean;
begin
  HideLongHint;
  if (FRowsCount = 0) or (FSelected < 0) and (FSelected >= FRowsCount) then
    Exit;
  p := FRows[FSelected];
  if not Assigned(p) then
    Exit;
  if not p^.HasChildren then begin
    // Если выделенное свойство не имеет дочерний подсвойств, то расширять или
    // свертывать в этом случае нечего. Если свойство типа Boolean, то
    // изменем его значение на противоположное
    if not ExpandingOnly then begin
      if p^.Kind = pkBoolean then begin
        ChangeBoolean(p);
        Invalidate;
      end;
    end;
    UpdateFocus;
    Exit;
  end;
  case ChangeType of
    tctChange:   e := not p^.Expanded;
    tctCollapse: e := False;
    tctExpand:   e := True;
    else         e := p^.Expanded;
  end;
  // меняем значение признака Extended, перестраиваем
  // дерево свойств и перерисовываем область окна инспектора
  if p^.Expanded <> e then begin
    p^.Expanded := e;
    pcw := ClientWidth;
    CreateRows;
    UpdateScrollBar;
    HideEditor;
    Invalidate;
    ShowEditor;
    // если ширина клиентской области увеличилась, значит
    // полоска скроллинга скрылась и все свойства могут поместиться в
    // окне. Если при этом верхнее свойство не отображалось,
    // то явно корректируем позицию списка свойств
    if pcw < ClientWidth then
      if FTopRow <> 0 then
        SetTopRow(0);
  end;
end;

// Навигации по свойствам от клавиатуры
procedure TGsvCustomObjectInspectorGrid.SetSelectedRowByKey(Key: Word);
var
  rc: Integer;
begin
  rc := ClientHeight div FRowHeight;
  case Key of
    VK_UP:    SetSelectedRow(FSelected - 1);
    VK_DOWN:  SetSelectedRow(FSelected + 1);
    VK_PRIOR: SetSelectedRow(FSelected - rc);
    VK_NEXT:  SetSelectedRow(FSelected + rc);
    VK_HOME:  SetSelectedRow(0);
    VK_END:   SetSelectedRow(FRowsCount - 1);
  end;
end;

// Этот метод вызывается редактом при изменении значения свойства
procedure TGsvCustomObjectInspectorGrid.ValueChanged(
  Info: PGsvObjectInspectorPropertyInfo; const Value: String);
begin
  if FRowsCount <> 0 then
    if HAS(_INPUT_TEXT, Info) then
      if DoGetStringValue(Info) <> Value then
        DoSetStringValue(Info, Value);
end;

procedure TGsvCustomObjectInspectorGrid.CreateParams(
  var Params: TCreateParams);
const
  BorderStyles: array[TBorderStyle] of DWORD = (0, WS_BORDER);
begin
  inherited;
  with Params do begin
    Style := Style or BorderStyles[FBorderStyle];
    if NewStyleControls and (FBorderStyle = bsSingle) then begin
      Style   := Style and not WS_BORDER;
      ExStyle := ExStyle or WS_EX_CLIENTEDGE;
    end;
  end;
  with Params.WindowClass do
    Style := Style and (CS_HREDRAW or CS_VREDRAW);
end;

procedure TGsvCustomObjectInspectorGrid.CreateWnd;
begin
  inherited;
  UpdateScrollBar;
end;

procedure TGsvCustomObjectInspectorGrid.Paint;
var
  i:      Integer;
  x0, x1: Integer;
  y0, y1: Integer;
  iMax:   Integer;
  dy, dg: Integer;
  r:      TRect;
  IntVal: Integer;

  procedure DrawLine(AColor: TColor; AX0, AY0, AX1, AY1: Integer);
  begin
    with Canvas do begin
      Pen.Color := AColor;
      MoveTo(AX0, AY0);
      LineTo(AX1, AY1);
    end;
  end;

  procedure DrawString;
  begin
    Canvas.TextRect(r, r.Left + VALUE_LEFT_MARGIN, r.Top + dy,
      TextWithLimit(FRows[i]^.LastValue));
  end;

  procedure DrawFloat;
  var
    f: Extended;
    v: String;
  begin
    v := FRows[i]^.LastValue;
    if v <> '' then begin
      try
        f := StrToFloat(v);
        if FRows[i]^.FloatFormat <> '' then
          v := Trim(FormatFloat(FRows[i]^.FloatFormat, f))
        else
          v := FloatToStr(f);
      except
      end;
    end;
    Canvas.TextRect(r, VALUE_LEFT_MARGIN + r.Left, r.Top + dy, v);
  end;

  procedure DrawTreeGlyph;
  var
    sr, dr: TRect;
  begin
    // координаты для рисования образа
    dr.Left   := x0 + GLYPH_MAGRIN - FLevelIndent;
    dr.Top    := y0 + dg;
    dr.Right  := dr.Left + GLYPH_TREE_SIZE;
    dr.Bottom := dr.Top + GLYPH_TREE_SIZE;
    // координаты образа в ресурсном bitmap
    if FRows[i]^.Expanded then sr.Left := 1
    else                       sr.Left := FGlyphs.Height + 1;
    sr.Top    := 1;
    sr.Right  := sr.Left + GLYPH_TREE_SIZE;
    sr.Bottom := sr.Top + GLYPH_TREE_SIZE;
    // отрисовка
    Canvas.CopyRect(dr, FGlyphs.Canvas, sr);
  end;

  procedure DrawBoolean;
  var
    sr, dr: TRect;
  begin
    // координаты для копирования графического образа CheckBox
    dr.Left   := r.Left + VALUE_LEFT_MARGIN;
    dr.Top    := r.Top + (r.Bottom - r.Top - GLYPH_CHECK_SIZE) div 2;
    dr.Right  := dr.Left + GLYPH_CHECK_SIZE;
    dr.Bottom := dr.Top + GLYPH_CHECK_SIZE;
    // координаты образа в ресурном bitmap'e
    if GsvGetBit(IntVal, FRows[i]^.Tag) then
      sr.Left := FGlyphs.Height * 3
    else
      sr.Left := FGlyphs.Height * 2;
    sr.Top    := 0;
    sr.Right  := sr.Left + GLYPH_CHECK_SIZE;
    sr.Bottom := sr.Top + GLYPH_CHECK_SIZE;
    // отрисовка образа
    Canvas.CopyRect(dr, FGlyphs.Canvas, sr);
  end;

  procedure DrawColor;
  var
    dr:  TRect;
    pc:  TColor;
    bc:  TColor;
  begin
    Canvas.TextRect(r, r.Left + VALUE_LEFT_MARGIN * 2 + 2 + COLOR_RECT_WIDTH,
      r.Top + dy, FRows[i]^.LastValue);
    dr.Left   := r.Left + VALUE_LEFT_MARGIN;
    dr.Top    := y0 + dg;
    dr.Right  := dr.Left + COLOR_RECT_WIDTH;
    dr.Bottom := dr.Top + COLOR_RECT_HEIGHT;
    pc := Canvas.Pen.Color;
    bc := Canvas.Brush.Color;
    Canvas.Pen.Color := clBlack;
    case FRows[i]^.Kind of
      pkColor,
      pkColorRGB: Canvas.Brush.Color := IntVal;
    end;
    Canvas.Rectangle(dr);
    Canvas.Pen.Color   := pc;
    Canvas.Brush.Color := bc;
  end;

begin
  inherited;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  if FRowsCount = 0 then
    Exit;

  if (Font.Name  <> Canvas.Font.Name) or
     (Font.Size  <> Canvas.Font.Size) or
     (Font.Style <> Canvas.Font.Style) or
     (FFontHeight = 0) then
  begin
    // определяем размер шрифта в пикселах
    Canvas.Font := Font;
    FFontHeight := Canvas.TextHeight('M');
  end;
  // вертикальное смещение для центрирования текста
  dy := ((FRowHeight - FFontHeight) div 2) - 1;
  if dy < 0 then
    dy := 0;
  // вертикальное смещение для центрирования графических образов
  dg := ((FRowHeight - GLYPH_TREE_SIZE) div 2) + 1;
  if dg < 0 then
    dg := 0;
  // индекс последного свойства, полностью или частично видимого
  // в окне инспектора
  iMax := FTopRow + ClientHeight div FRowHeight;
  if (ClientHeight mod FRowHeight) <> 0 then
    Inc(iMax); // есть частично видимое свойство
  if iMax > Pred(FRowsCount) then
    iMax := Pred(FRowsCount);
  // итерация по всем видимым свойствам
  for i := FTopRow to iMax do begin
    // горизонтальная линия сетки
    y0 := (i - FTopRow) * FRowHeight;
    y1 := y0 + FRowHeight;
    DrawLine(clBtnShadow, 0, y1, ClientWidth, y1);
    // графические образы древовидной структуры
    x0 := (FRows[i]^.Level + 1) * FLevelIndent;
    x1 := FDividerPosition;
    if FRows[i]^.HasChildren then
      DrawTreeGlyph;
    // отрисовка названия свойства
    SetRect(r, x0, y0 + 2, x1 - 1, y1 - 1);
    if FRows[i]^.Kind = pkFolder then begin
      // если свойство - папка, то рисуем на всю ширину окна
      Canvas.Font.Color := FFolderFontColor;
      Canvas.Font.Style := FFolderFontStyle;
      r.Right := ClientWidth;
      Canvas.TextRect(r, r.Left, r.Top + dy, DoGetCaption(FRows[i]));
      Canvas.Font.Color := Font.Color;
      Canvas.Font.Style := [];
    end
    else begin
      Canvas.TextRect(r, r.Left, r.Top + dy, DoGetCaption(FRows[i]));
      // отрисовка линии разделителя
      DrawLine(clBtnShadow, x1, y0 + 1, x1, y1);
      DrawLine(clBtnHighlight, x1 + 1, y0 + 1, x1 + 1, y1);
    end;
    // отрисовка значения свойства
    r.Left  := x1 + 2;
    r.Right := ClientWidth;
    if i = FSelected then begin
      // отрисовка границы выделенного свойства
      DrawLine(clBtnShadow, 0, y0, ClientWidth, y0);
      DrawLine(clBtnText, 0, y0 + 1, ClientWidth, y0 + 1);
      DrawLine(clBtnFace, 0, y1 - 1, ClientWidth, y1 - 1);
      DrawLine(clBtnHighlight, 0, y1, ClientWidth, y1);
      DrawLine(clBtnText, 0, y0 + 1, 0, y1 - 1);
    end;
    if HAS(_INTEGER, FRows[i]) then
      IntVal := DoGetIntegerValue(FRows[i]);
    FRows[i]^.LastValue := DoGetStringValue(FRows[i]);
    case FRows[i]^.Kind of
      pkText,
      pkDropDownList,
      pkDialog,
      pkReadOnlyText,
      pkImmediateText,
      pkTextList,
      pkSet,
      pkTextDialog:
        DrawString;
      pkBoolean:
        DrawBoolean;
      pkColor,
      pkColorRGB:
        DrawColor;
      pkFloat:
        DrawFloat;
    end;
  end;
end;

// Корректируем линию разделителя при изменении размеров окна инспектора
procedure TGsvCustomObjectInspectorGrid.Resize;
begin
  inherited;
  if (FDividerPosition > (ClientWidth - DIVIDER_LIMIT)) then
    FDividerPosition := ClientWidth - DIVIDER_LIMIT;
  if (FDividerPosition < DIVIDER_LIMIT) then
    FDividerPosition := DIVIDER_LIMIT;
  UpdateScrollBar;
  Invalidate;
  HideLongHint;
  HideEditor;
  ShowEditor;
end;

// При получении фокуса ввода корректируем его
procedure TGsvCustomObjectInspectorGrid.DoEnter;
begin
  inherited;
  UpdateFocus;
end;

// При потере фокуса ввода скрываем хинт
procedure TGsvCustomObjectInspectorGrid.DoExit;
begin
  inherited;
  HideLongHint;
end;

// После загрузки всех свойств устанавливаем позицию разделителя на середину
procedure TGsvCustomObjectInspectorGrid.Loaded;
begin
  inherited;
  FDividerPosition := ClientWidth div 2;
end;

procedure TGsvCustomObjectInspectorGrid.MouseDown(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  sel: Integer;
  xt:  Integer;
  xc:  Integer;
begin
  inherited;
  if Enabled and Visible and (not Focused) then
    SetFocus;
  if FRowsCount = 0 then
    Exit;
  if (Button <> mbLeft) then
    Exit;
  if DividerHitTest(X) then begin
    // начало перемещения линии разделителя. При перемещении скрываем редактор
    FMouseDivPos := X;
    HideEditor;
  end
  else begin
    sel := FSelected;
    // выделяем свойство по координатам мышки
    SetSelectedRowByMouse(X, Y);
    if sel <> FSelected then begin
      // если выделение изменилось, то контролируем попадание мышки
      // на графический образ и при попадании разворачиваем
      // или сворачиваем выделенную веточку (если у нее есть подсвойства)
      // или изменяем значение логической величины на противоположное
      if (FSelected >= 0) and (FSelected < FRowsCount) then begin
        xt := FRows[FSelected]^.Level * FLevelIndent;
        xc := FDividerPosition + VALUE_LEFT_MARGIN + 2 + GLYPH_CHECK_SIZE;
        if (X >= xt) and (X < (xt + FLevelIndent)) then
          ExpandingOrChangeBoolean(True, tctChange)
        else if ((X > FDividerPosition) and (X < xc)) then
          ExpandingOrChangeBoolean(False, tctChange);
      end;
    end;
  end;
end;

procedure TGsvCustomObjectInspectorGrid.MouseMove(Shift: TShiftState;
  X, Y: Integer);
var
  cur:      Integer;
  i:        Integer;
  ry:       Integer;
  rx:       Integer;
  tw:       Integer;
  ww:       Integer;
  HintProp: PGsvObjectInspectorPropertyInfo;
  HintRect: TRect;
  s:        String;
const
  GAP     = 2; // отступ текста
  MIN_CAP = 4; // минимальная видимая часть заголовка
begin
  inherited;
  if FRowsCount = 0 then begin
    if Cursor <> crDefault then
      Cursor := crDefault;
    Exit;
  end;
  if FMouseDivPos = -1 then begin
    if DividerHitTest(X) then
      cur := crHSplit
    else
      cur := crDefault;
    if Cursor <> cur then
      Cursor := cur;
  end
  else begin
    if (X >= DIVIDER_LIMIT) and (X < (ClientWidth - DIVIDER_LIMIT)) then
      DividerPosition := X;
  end;
  if Cursor <> crDefault then
    Exit;

  // отображаем хинт, если строка заголовка или значения не видна полностью
  s := '';
  SetRectEmpty(HintRect);
  i := FTopRow + (Y div FRowHeight);
  if (i < 0) or (i >= FRowsCount) then begin
    HideLongHint;
    Exit;
  end;
  ry := (i - FTopRow) * FRowHeight;
  HintProp := FRows[i];
  Assert(Assigned(HintProp));
  if HintProp^.Kind = pkFolder then begin
    s  := DoGetCaption(HintProp);
    rx := FLevelIndent * (HintProp^.Level + 1);
    ww := ClientWidth - rx - 1;
    Canvas.Font.Style := FFolderFontStyle;
    tw := Canvas.TextWidth(s);
    Canvas.Font.Style := [];
    if tw > ww then begin
      tw := Canvas.TextWidth(s);
      if (rx + MIN_CAP) < ClientWidth then
        SetRect(HintRect, rx - GAP - 1, ry, rx + tw + GAP - 1, ry + FRowHeight + 1)
      else
        SetRect(HintRect, 0, ry, tw + GAP * 2, ry + FRowHeight + 1)
    end;
  end
  else begin
    if X < FDividerPosition then begin
      s  := DoGetCaption(HintProp);
      rx := FLevelIndent * (HintProp^.Level + 1);
      ww := FDividerPosition - rx - 1;
      tw := Canvas.TextWidth(s);
      if tw > ww then begin
        if (rx + MIN_CAP) < FDividerPosition then
          SetRect(HintRect, rx - GAP - 1, ry, rx + tw + GAP - 1,
            ry + FRowHeight + 1)
        else
          SetRect(HintRect, 0, ry, tw + GAP * 2, ry + FRowHeight + 1)
      end;
    end
    else begin
      if Assigned(FEditor) then
        if (i = FSelected) and FEditor.Visible then
          Exit;
      s  := TextWithLimit(DoGetStringValue(HintProp));
      rx := FDividerPosition + 3;
      ww := ClientWidth - rx - 1;
      tw := Canvas.TextWidth(s);
      if tw > ww then
        SetRect(HintRect, rx - GAP - 1, ry, rx + tw + GAP - 1,
          ry + FRowHeight + 1);
    end;
  end;
  if IsRectEmpty(HintRect) or (s = '') then
    HideLongHint
  else
    ShowLongHint(HintRect, s);
end;

procedure TGsvCustomObjectInspectorGrid.MouseUp(Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button <> mbLeft then
    Exit;
  if FMouseDivPos <> -1 then begin
    // завершение перемещения линии разделителя и отображение редактора
    FMouseDivPos := -1;
    Invalidate;
    ShowEditor;
  end;
end;

// Прокрутка списка вниз
function TGsvCustomObjectInspectorGrid.DoMouseWheelDown(Shift: TShiftState;
  MousePos: TPoint): Boolean;
begin
  Result := True;
  if (FRowsCount = 0) or (FTopRow < 0) then
    Exit;
  SetTopRow(FTopRow + 1);
end;

// Прокрутка списка вверх
function TGsvCustomObjectInspectorGrid.DoMouseWheelUp(Shift: TShiftState;
  MousePos: TPoint): Boolean;
begin
  Result := True;
  if (FRowsCount = 0) or (FTopRow < 0) then
    Exit;
  SetTopRow(FTopRow - 1);
end;

// Навигация по свойства по нажатию клавиш
procedure TGsvCustomObjectInspectorGrid.KeyDown(var Key: Word;
  Shift: TShiftState);
var
  tct: TGsvObjectInspectorTreeChangeType;
begin
  case Key of
    VK_LEFT, VK_SUBTRACT, VK_OEM_MINUS: tct := tctCollapse;
    VK_RIGHT, VK_ADD, VK_OEM_PLUS:      tct := tctExpand;
    else                                tct := tctNone;
  end;
  if tct <> tctNone then begin
    if (FSelected >= 0) and (FSelected < FRowsCount) then begin
      if FRows[FSelected]^.HasChildren then begin
        Key := 0;
        inherited;
        ExpandingOrChangeBoolean(True, tct);
        Exit;
      end;
    end;
  end;
  SetSelectedRowByKey(Key);
  Key := 0;
  inherited;
  HideLongHint(True);
end;

// Расширение или свертывание подсвойств по клавишам Enter или Space
procedure TGsvCustomObjectInspectorGrid.KeyPress(var Key: Char);
begin
  if (Key = #13) or (Key = #32) then begin
    if (FSelected >= 0) and (FSelected < FRowsCount) then begin
      if FRows[FSelected]^.HasChildren then
        ExpandingOrChangeBoolean(True, tctChange)
      else if FRows[FSelected].Kind = pkBoolean then
        ExpandingOrChangeBoolean(False, tctChange);
    end;
  end;
  Key := #0;
  inherited;
end;

procedure TGsvCustomObjectInspectorGrid.KeyUp(var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_F1 then
    DoHelp;
  Key := 0;
  inherited;
end;

// Вызов внешнего обработчика, получающего значение свойства в виде строки
function TGsvCustomObjectInspectorGrid.DoGetStringValue(
  Info: PGsvObjectInspectorPropertyInfo): String;
begin
  Result := '';
  if not Assigned(Info) then
    Exit;
  if Assigned(FOnGetStringValue) then
    FOnGetStringValue(Self, Info, Result);
end;

// Вызов внешнего обработчика, устанавливающего значения свойства по его
// строковому представлению
procedure TGsvCustomObjectInspectorGrid.DoSetStringValue(
  Info: PGsvObjectInspectorPropertyInfo; const Value: String);
begin
  if csDesigning in ComponentState then
    Exit;
  if not Assigned(Info) then
    Exit;
  if Assigned(FOnSetStringValue) then begin
    FOnSetStringValue(Self, Info, Value);
    SmartInvalidate;
  end;
end;

function TGsvCustomObjectInspectorGrid.DoGetIntegerValue(
  Info: PGsvObjectInspectorPropertyInfo): LongInt;
begin
  Result := 0;
  if csDesigning in ComponentState then
    Exit;
  if not Assigned(Info) then
    Exit;
  if HAS(_INTEGER, Info) and Assigned(FOnGetIntegerValue) then
    FOnGetIntegerValue(Self, Info, Result);
end;

procedure TGsvCustomObjectInspectorGrid.DoSetIntegerValue(
  Info: PGsvObjectInspectorPropertyInfo; const Value: LongInt);
begin
  if csDesigning in ComponentState then
    Exit;
  if not Assigned(Info) then
    Exit;
  if HAS(_INTEGER, Info) and Assigned(FOnSetIntegerValue) then
    FOnSetIntegerValue(Self, Info, Value);
end;

procedure TGsvCustomObjectInspectorGrid.DoShowDialog;
begin
  PostMessage(Handle, WM_GSV_OBJECT_INSPECTOR_SHOW_DIALOG, 0, 0);
end;

// Вызов внешнего обработчика, который заполняет список значений
procedure TGsvCustomObjectInspectorGrid.DoFillList(
  Info: PGsvObjectInspectorPropertyInfo; List: TStrings);
begin
  if csDesigning in ComponentState then
    Exit;
  if Assigned(FOnFillList) and Assigned(Info) and Assigned(List) then
    FOnFillList(Self, Info, List);
end;

procedure TGsvCustomObjectInspectorGrid.DoHelp;
begin
  if csDesigning in ComponentState then
    Exit;
  if not Assigned(FOnHelp) then
    Exit;
  if (FSelected >= 0) and (FSelected < FRowsCount) then
    FOnHelp(Self, FRows[FSelected]);
end;

procedure TGsvCustomObjectInspectorGrid.DoHint(
  Info: PGsvObjectInspectorPropertyInfo);
begin
  if csDesigning in ComponentState then
    Exit;
  if Assigned(FOnHint) and Assigned(Info) then
    FOnHint(Self, Info);
end;

function TGsvCustomObjectInspectorGrid.DoGetCaption(
  Info: PGsvObjectInspectorPropertyInfo): string;
begin
  if Assigned(Info) then begin
    Result := Info^.Caption;
    if Assigned(FOnGetCaption) and (not (csDesigning in ComponentState)) then
      FOnGetCaption(Self, Info, Result);
  end
  else
    Result := '';
end;

// Начало инспекции нового объекта
procedure TGsvCustomObjectInspectorGrid.NewObject;
begin
  EnumProperties;
end;

// Очистка области инспектора - инспектируемый объект отсутствует
procedure TGsvCustomObjectInspectorGrid.Clear;
begin
  HideLongHint;
  HideEditor;
  FProperties.Clear;
  FRowsCount := 0;
  FTopRow    := -1;
  FSelected  := -1;
  UpdateScrollBar;
  Invalidate;
  DoHint(nil);
end;

// Этот метод может быть явно вызван из приложения для гарантии того, что
// начатое изменение значения свойства будет завершено. Метод можно вызывать
// в тех случаях, когда происходит какое-либо новое действие уровня приложения,
// не связанное с изменением фокуса ввода (например, нажатие на кнопку панели
// инструментов). Если меняется фокус ввода, то изменения будут сделаны
// автоматически
procedure TGsvCustomObjectInspectorGrid.AcceptChanges;
begin
  if not Assigned(FEditor) then
    Exit;
  if (FRowsCount = 0) or (FSelected < 0) or (FSelected >= FRowsCount) then
    Exit;
  if FEditor.Visible and FEditor.Modified then begin
    ValueChanged(FRows[FSelected], FEditor.EditText);
    FEditor.Modified := False;
  end;
end;

{ В отличие от Invalidate, метод SmartInvalidate обновляет инспектор
  только в том случае, если у инспектируемого объекта изменилось
  одно или несколько свойств, отображаемых в данный момент
  инспектором. Поле редактирования обновляется только в
  том случае, если редактируемый текст не был изменен, то есть,
  не находится в процессе редактирования. Метод SmartInvalidate
  можно вызывать из события Application.OnIdle, по какому-либо
  таймеру или по какому-либо другому событию
}
procedure TGsvCustomObjectInspectorGrid.SmartInvalidate;
var
  iMax: Integer;
  i:    Integer;
begin
  // блокировка на случай, если события поступают быстрее, чем могут быть
  // обработаны
  if FInvalidateLock then
    Exit;
  try
    FInvalidateLock := True;
    // индекс последного свойства, полностью или частично видимого
    // в окне инспектора
    iMax := FTopRow + ClientHeight div FRowHeight;
    if (ClientHeight mod FRowHeight) <> 0 then
      Inc(iMax); // есть частично видимое свойство
    if iMax > Pred(FRowsCount) then
      iMax := Pred(FRowsCount);
    // итерация по всем видимым свойствам
    if iMax > 0 then begin
      for i := FTopRow to iMax do begin
        if FRows[i]^.LastValue <> DoGetStringValue(FRows[i]) then begin
          Invalidate;
          UpdateEditor;
          Break;
        end;
      end;
    end;
  finally
    FInvalidateLock := False;
  end;
end;

procedure TGsvCustomObjectInspectorGrid.ExpandAll;
begin
  FProperties.ExpandAll(True);
  CreateRows;
  FTopRow   := -1;
  FSelected := -1;
  UpdateScrollBar;
  SetSelectedRow(0);
end;

procedure TGsvCustomObjectInspectorGrid.CollapseAll;
begin
  FProperties.ExpandAll(False);
  CreateRows;
  Invalidate;
  FTopRow   := -1;
  FSelected := -1;
  UpdateScrollBar;
  SetSelectedRow(0);
end;

function TGsvCustomObjectInspectorGrid.InplaceEditor: TCustomEdit;
begin
  Result := FEditor;
end;

function TGsvCustomObjectInspectorGrid.SelectedLeftBottom: TPoint;
var
  b: Integer;
begin
  if FSelected >= 0 then begin
    b      := (FSelected - FTopRow) * FRowHeight + FRowHeight;
    Result := ClientToScreen(Point(0, b));
  end
  else
    Result := ClientToScreen(Point(0, 0));
end;

function TGsvCustomObjectInspectorGrid.SelectedCenter: TPoint;
var
  y: Integer;
begin
  if FSelected >= 0 then begin
    y      := (FSelected - FTopRow) * FRowHeight + (FRowHeight div 2);
    Result := ClientToScreen(Point(ClientWidth div 2, y));
  end
  else
    Result := ClientToScreen(Point(0, 0));
end;

function TGsvCustomObjectInspectorGrid.SelectedInfo:
  PGsvObjectInspectorPropertyInfo;
begin
  if FSelected >= 0 then
    Result := FRows[FSelected]
  else
    Result := nil;
end;

function TGsvCustomObjectInspectorGrid.SelectedText: string;
begin
  if FSelected >= 0 then
    Result := DoGetStringValue(FRows[FSelected])
  else
    Result := '';
end;

// Установка выделенного свойства по его имени
procedure TGsvCustomObjectInspectorGrid.SetSelected(const aName: string);
var
  rc, s: Integer;
begin
  s := FProperties.SetSelected(aName);
  CreateRows;
  FTopRow   := 0;
  FSelected := -1;
  rc        := ClientHeight div FRowHeight;
  if s >= 0 then begin
    FTopRow := s - rc;
    if FTopRow < 0 then
      FTopRow := 0;
  end;
  UpdateScrollBar;
  if s >= 0 then
    SetSelectedRow(s);
end;

procedure TGsvCustomObjectInspectorGrid.ValidateStringValue(
  const Value: String);
begin
  if Assigned(FEditor) then
    FEditor.ValidateStringValue(Value);
end;


end.

