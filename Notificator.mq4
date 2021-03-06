//+------------------------------------------------------------------+
//|                                                   LineNotify.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2020, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.10"
#property strict
#property indicator_chart_window
#property indicator_buffers 0

#import "shell32.dll"
int ShellExecuteW(int hWnd,string lpVerb,string lpFile,string lpParameters,string lpDirectory,int nCmdShow);
#import

input bool line_notify = false;//ラインに通知をするか
input string line_token = "<token>";//LINEのアクセストークン

input string str = "Notify";//表示文字
input color clicked_color=clrAqua;//クリック時の色
input int set_position = 2;//ボタン設置位置(現在足から)

bool initialized =false;
bool comment_delete = true;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit(){
   if(!IsDllsAllowed()){
      Comment(
         "=================================\n"
         +"DLLの使用が許可されていません。\n"
         +"このインジケータを使用するときは「ツール->オプション->エキスパートアドバイザタブ」\n"
         +"よりDLLを使用するにチェックを入れてください。\n"
         +"インジケータはチャートから削除されました。\n"
         +"================================="
      );
      comment_delete = false;
      return 1;
   } else {
      Comment("");
   }
   //Print("Preinitilized Oninitの中から"+initialized);
   //初期化するにはろうそく足の描写が必須
   
   if(Bars>100){
      Refresh();
      initialized=true;
   }
   
   ChartSetInteger(NULL,CHART_EVENT_OBJECT_CREATE,true);
   ChartSetInteger(NULL,CHART_EVENT_OBJECT_DELETE,true);
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]){
//---
   if(Bars<100)return 0;
   if(!initialized){
      Refresh();
      initialized=true;   
   }
   
   static double pre_close = Close[0];
   static datetime tmp_time = Time[0];
   
   for(int i=0;i<ObjectsTotal();i++){
      int obj_type = ObjectType(ObjectName(i));
      if(obj_type == OBJ_HLINE || obj_type == OBJ_TREND || obj_type == OBJ_CHANNEL){
         //価格の取得　水平線とトレンドラインで別
         double price = 0;
         if(obj_type == OBJ_HLINE)  price = ObjectGetDouble(NULL,ObjectName(i),OBJPROP_PRICE);
         if(obj_type == OBJ_TREND)  price = ObjectGetValueByTime(NULL,ObjectName(i),Time[0]);
         if(obj_type == OBJ_CHANNEL)price = ObjectGetValueByTime(NULL,ObjectName(i),Time[0],0);
         
         if(ObjectGet(ObjectName(i)+"btn0",OBJPROP_COLOR)==clicked_color){
            if((pre_close-price)*(Close[0]-price) <= 0 ){
               if(line_notify)LineNotify(line_token,"Currency:"+Symbol()
                  +"\nPrice:"+DoubleToStr(price,3)
                  +"\nDescription:"+ObjectDescription(ObjectName(i))
                  +"\nRSI-15m:"+DoubleToStr(iRSI(NULL,PERIOD_M15,14,PRICE_CLOSE,0),1)
                  +"\nRSI-1h:"+DoubleToStr(iRSI(NULL,PERIOD_H1,14,PRICE_CLOSE,0),1)
                  +"\nRSI-4h:"+DoubleToStr(iRSI(NULL,PERIOD_H4,14,PRICE_CLOSE,0),1)
                  ,Symbol()+"ss.png");
               ObjectSetInteger(NULL,ObjectName(i)+"btn0",OBJPROP_COLOR,clrYellow);
            }
         } 
      } 
      //新しいろうそく足関数
      if(tmp_time!=Time[0]){
         //移動を行う
         ButtonUpdate(ObjectName(i));
      }
   }
   tmp_time=Time[0];
   pre_close=Close[0];
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam){
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(StringFind(sparam,"btn",0)>0){
         if(ObjectGet(sparam,OBJPROP_COLOR)==clrYellow){
            ObjectSetInteger(NULL,sparam,OBJPROP_COLOR,clicked_color);    // 色設定
         }
         else {
            ObjectSetInteger(NULL,sparam,OBJPROP_COLOR,clrYellow);
         }      
      }
   }
   if(id == CHARTEVENT_OBJECT_DRAG){
      ButtonUpdate(sparam);
   }
   if(id == CHARTEVENT_OBJECT_CREATE){
      ButtonUpdate(sparam);
   }
   if(id == CHARTEVENT_OBJECT_DELETE){
      if(ObjectFind(NULL,sparam+"btn0")==0)ObjectDelete(NULL,sparam+"btn0");
      //if(ObjectFind(NULL,sparam+"btn1")==0)ObjectDelete(NULL,sparam+"btn1");
   }
   if(id == CHARTEVENT_OBJECT_CHANGE){
      Refresh();
   }  
}

void OnDeinit(const int reason){
   Print("OnDeinit の呼び出し reason: "+IntegerToString(reason));
   if(reason!=3){
      //for(int i=ObjectsTotal()-1;i>=0;i--)
      for(int i=0;i<ObjectsTotal();i++){
         //ボタン削除
         if(StringFind(ObjectName(i),"btn",0)!=-1){ObjectDelete(NULL,ObjectName(i));Print("delete:"+ObjectName(i));}
      }
      if(comment_delete)Comment("");
   }
}


void Refresh(){
   Print("Refresh の呼び出し");
   for(int i=ObjectsTotal()-1;i>=0;i--){
      string obj_name = ObjectName(i);
      int start_btn = StringFind(obj_name,"btn",0);
      if(start_btn>1){
         //ボタンに類するラインが存在しなかったら
         if(ObjectFind(NULL,StringSubstr(obj_name,0,start_btn))<0){
            ObjectDelete(NULL,obj_name);
            Print("Delete - LineName:"+StringSubstr(obj_name,0,start_btn)+" ChartNum:"+IntegerToString(ObjectFind(NULL,StringSubstr(obj_name,0,start_btn)))+" Name:"+obj_name);
         }
      }
   }
   for(int i=ObjectsTotal()-1;i>=0;i--){
      ButtonUpdate(ObjectName(i));
   }
}

void ButtonUpdate(string obj_name){
   //存在確認はメインチャートにあるかどうかなので0を使用する。
   int obj_type = ObjectType(obj_name);
   datetime position_time = Time[0]+Period()*60*set_position;
  // datetime position_time2 = ChartGetDouble(NULL,CHART_PRICE_MAX,0);
   if(obj_type == OBJ_HLINE){
      if(ObjectFind(NULL,obj_name+"btn0")==0){
         ObjectMove(NULL,obj_name+"btn0",0,position_time,ObjectGetDouble(NULL,obj_name,OBJPROP_PRICE));
      } else {
         CreateButton(obj_name+"btn0",position_time,ObjectGetDouble(NULL,obj_name,OBJPROP_PRICE));
      }
   } else if(obj_type == OBJ_TREND){
      if(ObjectFind(NULL,obj_name+"btn0")==0){
         ObjectMove(NULL,obj_name+"btn0",0,position_time,ObjectGetValueByTime(NULL,obj_name,position_time));
      } else {
         CreateButton(obj_name+"btn0",position_time,ObjectGetValueByTime(NULL,obj_name,position_time));
      }
   } else if(obj_type == OBJ_CHANNEL){
      //    値を取得するときおかしな値になるときがある。
      double price0 = ObjectGetValueByTime(NULL,obj_name,position_time,0);
      //double price1 = ObjectGetValueByTime(NULL,obj_name,position_time,1);
      //Print("Price0: ",price0,"     Price1: ",price1);
      if(0< price0 && price0 < ChartGetDouble(NULL,CHART_PRICE_MAX,0)*10){
         if(ObjectFind(NULL,obj_name+"btn0")==0){
            ObjectMove(NULL,obj_name+"btn0",0,position_time,price0);
            Print("Move - Name: "+obj_name+"btn0"+", To: "+DoubleToStr(price0,3));
         } else {
            CreateButton(obj_name+"btn0",position_time,price0);
            Print("Create - Name: "+obj_name+"btn0");
         }  
      }
      /*
      if(0< price1 && price1 < ChartGetDouble(NULL,CHART_PRICE_MAX,0)*10){
         if(ObjectFind(NULL,obj_name+"btn1")==0){
            ObjectMove(NULL,obj_name+"btn1",0,position_time2,price1);
            Print("Move - Name: "+obj_name+"btn1"+", To: "+DoubleToStr(price1,3));
         } else {
            CreateButton(obj_name+"btn1",position_time,price1);
            Print("Create - Name: "+obj_name+"btn1");
         }
      }
      */
   }
}
//メインボタン
void CreateButton(string btn_name,datetime time, double price){
   ObjectCreate(NULL,btn_name,OBJ_TEXT,0,time,price);
   ObjectSetInteger(NULL,btn_name,OBJPROP_COLOR,clrYellow);    // 色設定
   ObjectSetInteger(NULL,btn_name,OBJPROP_WIDTH,10);           // 幅設定
   ObjectSetInteger(NULL,btn_name,OBJPROP_BACK,false);         // オブジェクトの背景表示設定
   ObjectSetInteger(NULL,btn_name,OBJPROP_SELECTABLE,false);   // オブジェクトの選択可否設定
   ObjectSetInteger(NULL,btn_name,OBJPROP_SELECTED,false);     // オブジェクトの選択状態
   ObjectSetInteger(NULL,btn_name,OBJPROP_HIDDEN,true);        // オブジェクトリスト表示設定
   ObjectSetInteger(NULL,btn_name,OBJPROP_ZORDER,0);           // オブジェクトのチャートクリックイベント優先順位        
   ObjectSetInteger(NULL,btn_name,OBJPROP_ANCHOR,ANCHOR_TOP);  // アンカータイプ
   ObjectSetInteger(NULL,btn_name,OBJPROP_FONTSIZE,10);        // フォントサイズ
   ObjectSetString(NULL,btn_name,OBJPROP_TEXT,str);            // 表示するテキスト
   ObjectSetString(NULL,btn_name,OBJPROP_FONT,"Arial");   // フォント
}


void LineNotify(string token,string message,string filename = NULL,int ss_x = 600, int ss_y = 400){
   string command_pal = "-X POST -H \"Authorization: Bearer "+token+"\" -F \"message=\n"+message+"\"";
   Print(command_pal);
   if(filename!=NULL && filename!=""){
      ChartScreenShot(0,filename,ss_x,ss_y,ALIGN_RIGHT);
      command_pal += " -F \"imageFile=@"+TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL4\\Files\\"+filename+"\"";
   }
   command_pal += " https://notify-api.line.me/api/notify";
   ShellExecuteW(0,NULL,"curl",command_pal,NULL,0);                  
}


















/*
#import "wininet.dll"
int InternetAttemptConnect(int x);
int InternetOpenW(string &sAgent,int lAccessType,string &sProxyName,string &sProxyBypass,int lFlags);
int InternetConnectW(int hInternet,string &lpszServerName,int nServerPort,string &lpszUsername,string &lpszPassword,int dwService,int dwFlags,int dwContext);
int HttpOpenRequestW(int hConnect,string &lpszVerb,string &lpszObjectName,string &lpszVersion,string lpszReferer,string &lplpszAcceptTypes[],uint dwFlags,int dwContext);
bool HttpSendRequestW(int hRequest,string &lpszHeaders,int dwHeadersLength,uchar &lpOptional[],int dwOptionalLength);
int HttpQueryInfoW(int hRequest,int dwInfoLevel,uchar &lpvBuffer[],int &lpdwBufferLength,int &lpdwIndex);
int InternetOpenUrlW(int hInternet,string &lpszUrl,string &lpszHeaders,int dwHeadersLength,int dwFlags,int dwContext);
int InternetReadFile(int hFile,uchar &sBuffer[],int lNumBytesToRead,int &lNumberOfBytesRead);
int InternetCloseHandle(int hInet);
#import

//To make it clear, we will use the constant names from wininet.h.
#define OPEN_TYPE_PRECONFIG        0        // use the configuration by default

#define INTERNET_SERVICE_HTTP      3        //HTTPサービス
#define HTTP_QUERY_CONTENT_LENGTH  5
#define DEFAULT_HTTPS_PORT         443

#define FLAG_KEEP_CONNECTION    0x00400000  // do not terminate the connection
#define FLAG_PRAGMA_NOCACHE     0x00000100  // no cashing of the page
#define FLAG_RELOAD             0x80000000  // receive the page from the server when accessing it
#define FLAG_SECURE             0x00800000  // use PCT/SSL if applicable (HTTP)
#define FLAG_NO_COOKIES         0x00080000  // no using cookies
#define FLAG_NO_CACHE_WRITE     0x04000000  // 


void LineNotify(string token,string message){
   string headers = "Authorization: Bearer " + token + "\r\n";
   headers += "Content-Type: application/x-www-form-urlencoded\r\n";
   uchar post[];
   StringToCharArray("message=" + message, post, 0, WHOLE_ARRAY, CP_UTF8);
   Print(request("notify-api.line.me",DEFAULT_HTTPS_PORT,headers,"/api/notify.php",post));
}

void DiscordNotify(string bot, string webhook,string message){
   string headers = "Content-Type: application/json\r\n";
   uchar post[];
   StringToCharArray("{\"username\":\""+bot+"\",\"content\":\""+message+"\"}", post, 0, WHOLE_ARRAY, CP_UTF8);
   Print(request("discordapp.com",DEFAULT_HTTPS_PORT,headers,StringSubstr(webhook,20),post));
 
}

string request(string host, int port, string headers, string object, uchar &post[]){
   //DLLの許可をOnInitにて確認する。
   
   if(host==""){
      return "Host is not specified";
   }
   
   string UserAgent = "Mozilla/5.0";
   string null    = "";
   string Vers    = "HTTP/1.1";
   string POST    = "POST";
   string accept[1] = {"**"};//スラッシュを省いた
   
   int session = InternetOpenW(UserAgent, 0, null, null, 0);
   //Print("session:"+IntegerToString(session));
   if(session > 0){
      int connect = InternetConnectW(session, host, port, null, null, INTERNET_SERVICE_HTTP, 0, 0);
      //Print("connect:"+IntegerToString(connect));
      if (connect > 0){
      //------------connection success------------------
         string result = "";
         int hRequest = HttpOpenRequestW(connect, POST, object, Vers, null, accept, FLAG_SECURE|FLAG_KEEP_CONNECTION|FLAG_RELOAD|FLAG_PRAGMA_NOCACHE|FLAG_NO_COOKIES|FLAG_NO_CACHE_WRITE, 0);
         //Print("Reques:"+IntegerToString(hRequest));
         if(hRequest > 0){
            bool hSend = HttpSendRequestW(hRequest, headers, StringLen(headers), post, ArraySize(post)-1);
            //Print("send:"+IntegerToString(hSend));
            if(hSend){
               InternetCloseHandle(hSend);
               result += "Message ["+CharArrayToString(post)+"] has been sent";
            } else {
               result += "HttpSendRequest error";
            }
            InternetCloseHandle(hRequest);
         } else {
            result +=  "HttpOpenRequest error";
         }
         InternetCloseHandle(connect);
         InternetCloseHandle(session);
         return result;
      //-----------------------------
      } else {
         InternetCloseHandle(session); 
         return "InternetConnect error. Connect:"+IntegerToString(connect);
      }
   } else{
      return "InternetOpen error";
   }
}
*/