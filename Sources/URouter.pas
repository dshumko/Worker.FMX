unit URouter;

interface
uses System.Classes, System.types, System.Generics.Defaults,
System.Generics.Collections, FMX.TabControl;

type

  TRoutesStack=class(TStack<TTabItem>)
  public
    tbc:TTabControl;
    Action : TChangeTabAction;
    procedure GoBack;
    procedure Go(const AFrom, ATo: string);
    function TabByName(const AName:string):TTabItem;
  end;

var
  Router:TRoutesStack;
implementation

uses
  System.SysUtils;

{ TRoutesStack }

procedure TRoutesStack.Go(const AFrom, ATo: string);
var tabFrom,tabTo:TTabItem;
  i: Integer;
begin
  tabFrom := TabByName(AFrom);
  tabTo := TabByName(ATo);
  if tabFrom=nil then
    raise Exception.Create('Ошибка перехода. Не найдена исходная страница');
  if tabTo=nil then
    raise Exception.Create('Ошибка перехода. Не найдена конечная страница');
  push(tabFrom);
  action.Tab := tabTo;
  action.Execute;
end;

procedure TRoutesStack.GoBack;
begin
  if Count>0 then
  begin
    Action.Tab := Pop;
    Action.Execute;
  end;
end;

function TRoutesStack.TabByName(const AName: string): TTabItem;
var i:integer;
begin
  for i := 0 to tbc.TabCount-1 do
  begin
    if SameText( tbc.Tabs[i].Name, AName) then
    begin
      result := tbc.Tabs[i];
      exit;
    end;
  end;
  Result := nil;
end;

initialization
  Router := TRoutesStack.Create;

finalization

  Router.Free;
  Router:=NIL;

end.
