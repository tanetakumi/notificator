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
   
   //初期化するにはろうそく足の描写が必須
   if(Bars>100){
      Initialize();
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
      Initialize();
      initialized=true;   
   }
   
   static double pre_close = Close[0];
   static datetime tmp_time = Time[0];
   
   for(int i=0;i<ObjectsTotal();i++){
      int obj_type = ObjectType(ObjectName(i));
      if(obj_type == OBJ_HLINE || obj_type == OBJ_TREND){
         //価格の取得　水平線とトレンドラインで別
         double price = 0;
         if(obj_type == OBJ_HLINE)price = ObjectGetDouble(NULL,ObjectName(i),OBJPROP_PRICE);
         if(obj_type == OBJ_TREND)price = ObjectGetValueByTime(NULL,ObjectName(i),Time[0]);
         
         if(ObjectGet(ObjectName(i)+"btn",OBJPROP_COLOR)==clicked_color){
            if((pre_close-price)*(Close[0]-price) <= 0 ){
               if(line_notify)LineNotify(line_token,"通貨ペア:"+Symbol()+"\n価格:"+DoubleToStr(price,3)+"\nライン名:"+ObjectName(i));
               ObjectSetInteger(NULL,ObjectName(i)+"btn",OBJPROP_COLOR,clrYellow);
            }
         }
         //新しいろうそく足関数
         if(tmp_time!=Time[0]){
            //移動を行う
            ObjectMove(NULL,ObjectName(i)+"btn",0,Time[0]+Period()*60*set_position,price);
         }   
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
      int obj_type = ObjectType(sparam);
      if(obj_type==OBJ_HLINE || obj_type == OBJ_TREND){
         double price = 0;
         if(obj_type == OBJ_HLINE)price = ObjectGetDouble(NULL,sparam,OBJPROP_PRICE);
         if(obj_type == OBJ_TREND)price = ObjectGetValueByTime(NULL,sparam,Time[0]);
         ObjectMove(NULL,sparam+"btn",0,Time[0]+Period()*60*set_position,price);
      }
   }
   if(id == CHARTEVENT_OBJECT_CREATE){
      int obj_type = ObjectType(sparam);
      if(obj_type==OBJ_HLINE || obj_type == OBJ_TREND){
         double price = 0;
         if(obj_type == OBJ_HLINE)price = ObjectGetDouble(NULL,sparam,OBJPROP_PRICE);
         if(obj_type == OBJ_TREND)price = ObjectGetValueByTime(NULL,sparam,Time[0]);
         CreateButton(sparam,price);
      }
   }
   if(id == CHARTEVENT_OBJECT_DELETE){
      for(int i=ObjectsTotal()-1;i>=0;i--){
         //ボタン削除
         if(ObjectName(i) == sparam+"btn")ObjectDelete(NULL,ObjectName(i));
      }
   }   
}

void OnDeinit(const int reason){
   if(reason!=3){
      for(int i=ObjectsTotal()-1;i>=0;i--){
         //ボタン削除
         if(StringFind(ObjectName(i),"btn",0)!=-1)ObjectDelete(NULL,ObjectName(i));
      }
      if(comment_delete)Comment("");
   }
}


void Initialize(){
   for(int i=0;i<ObjectsTotal();i++){
      int obj_type = ObjectType(ObjectName(i));
      if(obj_type == OBJ_HLINE || obj_type == OBJ_TREND){
         double price = 0;
         if(obj_type == OBJ_HLINE)price = ObjectGetDouble(NULL,ObjectName(i),OBJPROP_PRICE);
         if(obj_type == OBJ_TREND)price = ObjectGetValueByTime(NULL,ObjectName(i),Time[0]);
         
         //オブジェクトがあれば移動させる
         if(ObjectFind(NULL,ObjectName(i)+"btn")==0){
            ObjectMove(NULL,ObjectName(i)+"btn",0,Time[0]+Period()*60*set_position,price);
         }
         //なければ作成
         else{
            CreateButton(ObjectName(i),price);
         }
      }
   }  
}
//メインボタン
void CreateButton(string object_name,double price){
   ObjectCreate(NULL,object_name+"btn",OBJ_TEXT,0,Time[0]+Period()*60*set_position,price);
   ObjectSetInteger(NULL,object_name+"btn",OBJPROP_COLOR,clrYellow);    // 色設定
   ObjectSetInteger(NULL,object_name+"btn",OBJPROP_WIDTH,10);           // 幅設定
   ObjectSetInteger(NULL,object_name+"btn",OBJPROP_BACK,false);         // オブジェクトの背景表示設定
   ObjectSetInteger(NULL,object_name+"btn",OBJPROP_SELECTABLE,false);   // オブジェクトの選択可否設定
   ObjectSetInteger(NULL,object_name+"btn",OBJPROP_SELECTED,false);     // オブジェクトの選択状態
   ObjectSetInteger(NULL,object_name+"btn",OBJPROP_HIDDEN,true);        // オブジェクトリスト表示設定
   ObjectSetInteger(NULL,object_name+"btn",OBJPROP_ZORDER,0);           // オブジェクトのチャートクリックイベント優先順位        
   ObjectSetInteger(NULL,object_name+"btn",OBJPROP_ANCHOR,ANCHOR_TOP);  // アンカータイプ
   ObjectSetInteger(NULL,object_name+"btn",OBJPROP_FONTSIZE,10);        // フォントサイズ
   ObjectSetString(NULL,object_name+"btn",OBJPROP_TEXT,str);            // 表示するテキスト
   ObjectSetString(NULL,object_name+"btn",OBJPROP_FONT,"Arial");   // フォント
}


void LineNotify(string token,string message,string filepath = NULL,int ss_x = 600, int ss_y = 400){
   string command_pal = "-X POST -H \"Authorization: Bearer "+token+"\" -F \"message="+message+"\"";
                        
   if(filepath!=NULL && filepath!=""){
      ChartScreenShot(0,filepath,ss_x,ss_y,ALIGN_RIGHT);
      command_pal += " -F \"imageFile=@"+TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL4\\Files\\"+filepath+"\"";
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