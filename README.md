# Notificator 

MT4でラインクロスしたときにLINEにスクショとメッセージを送ります。


## 対応しているオブジェクト

1. Horizontal Line
2. Channel Line
3. Trend Line


Channel Line　に関しては二本線があり、どちらも通知するか、一方だけ通知するかで迷ったが
どちらも通知するとラインに付随する文字がかぶるので現在は一方のみ(Line 0)


## 問題点

- たまに一回のクロスで何度も通知処理が入り、DLLがスタックすることがある。
    - OnTimer を使用して、改善をする。

- やはり半分自動でエントリーする機能が欲しかったりする。

- windows curl コマンドを使用しているためUTF-8に対応した日本語のメッセージ、そしてファイルパスが使えない。すなわちフォルダのuser名が日本語の人はファイルを送ることができない。これは大問題である。
    - HalfAutotrade というEAを新しく作成し、そこでwininet.dllを使用
    ```Content-Type: multipart/form-data;```を使用した画像送信について扱ってみる。


## 技術
Editor: VScode metaeditor

言語: mq4

##　キャプチャ画像

![キャプチャ](https://user-images.githubusercontent.com/75787495/128267385-122b2be5-49b2-48b8-8920-a3dc37f735b6.PNG)

![IMG_8577](https://user-images.githubusercontent.com/75787495/128267423-7899dd5c-672d-4140-9efc-cd1d205b4576.PNG)

