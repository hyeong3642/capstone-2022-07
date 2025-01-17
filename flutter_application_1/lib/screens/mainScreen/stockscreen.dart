// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contained_tab_bar_view/contained_tab_bar_view.dart';
// ignore_for_file: prefer_const_constructors, prefer_const_constructors_in_immutables, non_constant_identifier_names, prefer_const_literals_to_create_immutables, prefer_typing_uninitialized_variables
import 'package:flutter/material.dart';
import 'package:flutter_application_1/Color/Color.dart';
import 'package:flutter_application_1/Components/indicator.dart';
import 'package:flutter_application_1/Components/main_app_bar.dart';
import 'package:flutter_application_1/Components/numFormat.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yahoofin/yahoofin.dart';

class Stockscreen extends StatefulWidget {
  Stockscreen({
    Key? key,
    required this.stockName,
    required this.stockCode,
  }) : super(key: key);

  final String stockName;
  final String stockCode;

  @override
  State<Stockscreen> createState() => _StockscreenState();
}

class _StockscreenState extends State<Stockscreen> {
  late TooltipBehavior _tooltipBehavior;
  @override
  void initState() {
    _tooltipBehavior = TooltipBehavior(
      enable: true, format: 'point.x: point.y', header: '',
      // Templating the tooltip
    );
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    // animationController.dispose() instead of your controller.dispose
  }

  late Color stockColor;

  List<_ChartData> dayData = [];
  List<_ChartData> monthData = [];
  List<_ChartData> yearData = [];
  List<_ChartData> tenYearData = [];

  List<num>? dayVolume = [];
  List<num>? dayTime = [];
  List<num>? monthVolume = [];
  List<num>? monthTime = [];
  List<num>? yearVolume = [];
  List<num>? yearTime = [];
  List<num>? tenYearVolume = [];
  List<num>? tenYearTime = [];

  var dayMinimum;
  var monthMinimum;
  var yearMinimum;
  var tenYearMinimum;

  Map<String, dynamic> firebaseStockData = {};
  List<Map<String, dynamic>> newsDataList = [];
  String updatedTime = "";
  Future getStockInfo() => AsyncMemoizer().runOnce(
        () async {
          CollectionReference stocks =
              FirebaseFirestore.instance.collection('stock');
          QuerySnapshot stockData = await stocks
              .where('stockName', isEqualTo: widget.stockName)
              .get();

          await FirebaseFirestore.instance
              .collection('stock')
              .where('stockName', isEqualTo: '코스피')
              .get()
              .then((QuerySnapshot qs) {
            Map<String, dynamic> marketdata =
                qs.docs[0].data() as Map<String, dynamic>;
            updatedTime = marketdata['updatedTime'];
          });

          CollectionReference news =
              stocks.doc(stockData.docs[0].id).collection("news");

          Future<void> _getNewsList(List<Map<String, dynamic>> list) async {
            await news.orderBy("timestamp", descending: true).get().then(
              (QuerySnapshot qs) {
                for (var doc in qs.docs) {
                  Map<String, dynamic> topnews =
                      doc.data() as Map<String, dynamic>;
                  if (topnews["label"] != "1" && topnews["label"] != 1) {
                    list.add(topnews);
                  }
                }
              },
            );
          }

          _getNewsList(newsDataList);

          if (stockData.size == 0) {
            return null;
          } else {
            return stockData.docs[0].data();
          }
        },
      );

  //Firebase 적용사항

  Future getDayData(String ticker) async {
    var yfin = YahooFin();
    StockHistory hist = yfin.initStockHistory(ticker: ticker);
    StockChart chart = await yfin.getChartQuotes(
        stockHistory: hist,
        interval: StockInterval.thirtyMinute,
        period: StockRange.oneDay);

    if (chart.chartQuotes != null) {
      dayVolume = chart.chartQuotes!.close;
      dayTime = chart.chartQuotes!.timestamp;

      for (int i = 0; i < dayVolume!.length; i++) {
        if (dayTime!.isNotEmpty) {
          if (dayVolume![i] == null || dayTime![i] == null) {
            continue;
          }
          var date =
              DateTime.fromMillisecondsSinceEpoch(dayTime![i].toInt() * 1000);
          dayData.add(_ChartData(date, dayVolume![i].toDouble()));
        }
      }
    }

    return "";
  }

  Future getMonthData(String ticker) async {
    var yfin = YahooFin();
    StockHistory hist = yfin.initStockHistory(ticker: ticker);
    StockChart chart = await yfin.getChartQuotes(
        stockHistory: hist,
        interval: StockInterval.oneDay,
        period: StockRange.oneMonth);

    if (chart.chartQuotes != null) {
      monthVolume = chart.chartQuotes!.close;
      monthTime = chart.chartQuotes!.timestamp;

      for (int i = 0; i < monthVolume!.length; i++) {
        if (monthTime!.isNotEmpty) {
          if (monthVolume![i] == null || monthTime![i] == null) {
            continue;
          }
          var date =
              DateTime.fromMillisecondsSinceEpoch(monthTime![i].toInt() * 1000);
          monthData.add(_ChartData(date, monthVolume![i].toDouble()));
        }
      }
    }

    return "";
  }

  Future getYearData(String ticker) async {
    var yfin = YahooFin();
    StockHistory hist = yfin.initStockHistory(ticker: ticker);
    StockChart chart = await yfin.getChartQuotes(
        stockHistory: hist,
        interval: StockInterval.oneMonth,
        period: StockRange.oneYear);

    if (chart.chartQuotes != null) {
      yearVolume = chart.chartQuotes!.close;
      yearTime = chart.chartQuotes!.timestamp;

      for (int i = 0; i < yearVolume!.length; i++) {
        if (yearVolume![i] == null || yearTime![i] == null) {
          continue;
        }
        if (yearTime!.isNotEmpty) {
          var date =
              DateTime.fromMillisecondsSinceEpoch(yearTime![i].toInt() * 1000);
          yearData.add(_ChartData(date, yearVolume![i].toDouble()));
        }
      }
    }

    return "";
  }

  Future getTenYearData(String ticker) async {
    var yfin = YahooFin();
    StockHistory hist = yfin.initStockHistory(ticker: ticker);
    StockChart chart = await yfin.getChartQuotes(
        stockHistory: hist,
        interval: StockInterval.oneMonth,
        period: StockRange.tenYear);

    if (chart.chartQuotes != null) {
      tenYearVolume = chart.chartQuotes!.close;
      tenYearTime = chart.chartQuotes!.timestamp;

      for (int i = 0; i < tenYearVolume!.length; i++) {
        if (tenYearVolume![i] == null || tenYearTime![i] == null) {
          continue;
        }
        if (tenYearTime!.isNotEmpty) {
          var date = DateTime.fromMillisecondsSinceEpoch(
              tenYearTime![i].toInt() * 1000);
          tenYearData.add(_ChartData(date, tenYearVolume![i].toDouble()));
        }
      }
    }
    // print(tenYearData);

    return "";
  }

  Future chartInit(String ticker) => AsyncMemoizer().runOnce(
        () async {
          String temp = ticker;
          if (ticker != "^KS11" &&
              ticker != "^KQ11" &&
              ticker != "^DJI" &&
              ticker != "^IXIC" &&
              ticker != "^N225") temp += ".KS";
          await getMonthData(temp);
          await getYearData(temp);
          await getTenYearData(temp);
          await getDayData(temp);
        },
      );

  // 종목 이름,가격,대비,긍/부정, 관심

  Widget TabContainer(String text) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
      ),
      child: Align(
        alignment: Alignment.center,
        child: Text(text),
      ),
    );
  }

  Widget InfoTabContainer(Size size, String text) {
    return Container(
      margin:
          EdgeInsets.only(left: size.width * 0.03, right: size.width * 0.03),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        // border: Border.all(color: (Colors.grey[400])!, width: ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: Text(text),
      ),
    );
  }

  Widget Stockmain(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin:
              EdgeInsets.only(left: size.width * 0.06, top: size.height * 0.01),
          child: Text(
            updatedTime + " 기준",
            style: TextStyle(
              color: Color.fromRGBO(0, 0, 0, 0.7),
              fontSize: size.width * 0.025,
              fontWeight: FontWeight.normal,
              height: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          margin: EdgeInsets.only(
              bottom: size.height * 0.02,
              left: size.width * 0.05,
              right: size.width * 0.05,
              top: size.height * 0.01),
          padding: EdgeInsets.all(size.width * 0.01),
          width: size.width * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            color: Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Stockinfo(
                      size,
                      firebaseStockData["stockName"],
                      firebaseStockData["stockCode"],
                      firebaseStockData["stockPrice"],
                      firebaseStockData["stockPerChange"],
                      firebaseStockData["stockChange"]),
                  Container(
                    padding: EdgeInsets.all(size.width * 0.01),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color.fromRGBO(240, 240, 240, 1),
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                            "시간당 호재 기사 개수: ${firebaseStockData["TimePerPositiveNewsCount"]}"),
                        SizedBox(
                          height: size.height * 0.005,
                        ),
                        Text(
                            "시간당 악재 기사 개수: ${firebaseStockData["TimePerNegativeNewsCount"]}"),
                      ],
                    ),
                  )
                ],
              ),
              chartTab(size),
            ],
          ),
        ),
      ],
    );
  }

  Widget chartTab(Size size) {
    return Center(
      child: SizedBox(
        width: size.width * 0.9,
        height: size.height * 0.395,
        child: ContainedTabBarView(
          tabs: [
            TabContainer("1D"),
            TabContainer("1M"),
            TabContainer("1Y"),
            TabContainer("10Y"),
          ],
          initialIndex: 1,
          tabBarProperties: TabBarProperties(
            padding: EdgeInsets.all(8),
            indicatorPadding: EdgeInsets.only(
                left: size.width * 0.03, right: size.width * 0.03),
            unselectedLabelColor: Colors.grey[400],
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Color(0xff0039A4)),
            margin: EdgeInsets.only(bottom: 8.0),
            position: TabBarPosition.bottom,
            background: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
              ),
            ),
          ),
          views: [
            DayChart(size, dayData),
            MonthChart(size, monthData),
            YearChart(size, yearData),
            TenYearChart(size, tenYearData),
          ],
        ),
      ),
    );
  }

  Widget infoTab(Size size, Map<String, dynamic> firebaseStockData) {
    return Center(
      child: Container(
        width: size.width * 0.9,
        height: size.height * 0.6,
        margin: EdgeInsets.only(bottom: size.height * 0.05),
        child: ContainedTabBarView(
          tabs: [
            InfoTabContainer(size, "종목 뉴스"),
            InfoTabContainer(size, "종목 정보"),
          ],
          initialIndex: 0,
          tabBarProperties: TabBarProperties(
            padding: EdgeInsets.all(8),
            indicatorPadding: EdgeInsets.only(
                left: size.width * 0.03, right: size.width * 0.03),
            labelStyle: TextStyle(color: Color(0xff0039A4)),
            labelColor: Color(0xff0039A4),
            unselectedLabelColor: Colors.grey[400],
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                // border: Border.all(color: (Colors.grey[400])!),
                border: Border.all(color: Color(0xff0039A4), width: 1),
                color: Color(0xffEFF1F6)),
            margin: EdgeInsets.only(bottom: 8.0),
            background: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
            ),
          ),
          views: [
            newsInfo(size, '종목 뉴스', firebaseStockData),
            stockInfo(size, '종목 정보', firebaseStockData),
          ],
          onChange: (index) {},
        ),
      ),
    );
  }

  Widget Chart(Size size, List<_ChartData> data, var minimum) {
    return Column(
      children: [
        Container(
          // margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
          width: size.width * 0.9,
          height: size.height * 0.3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            color: Colors.white,
          ),
          child: SizedBox(
            width: size.width * 0.9 * 0.9,
            height: size.height * 0.4,
            child: SfCartesianChart(
              plotAreaBorderColor: Colors.transparent,
              primaryXAxis: DateTimeAxis(isVisible: true),
              primaryYAxis: NumericAxis(
                minimum: minimum,
                isVisible: false,
              ),
              tooltipBehavior: _tooltipBehavior,
              // zoomPanBehavior: _zoompan,
              series: <ChartSeries<_ChartData, DateTime>>[
                AreaSeries<_ChartData, DateTime>(
                  dataSource: data,
                  borderDrawMode: BorderDrawMode.top,
                  borderWidth: 2,
                  borderColor: stockColor,
                  xValueMapper: (_ChartData data, _) => data.x,
                  yValueMapper: (_ChartData data, _) => data.y,
                  color: stockColor,
                  gradient: LinearGradient(colors: [
                    stockColor.withOpacity(0.1),
                    stockColor,
                  ], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget DayChart(Size size, List<_ChartData> data) {
    return Chart(size, data, dayMinimum);
  }

  Widget MonthChart(Size size, List<_ChartData> data) {
    return Chart(size, data, monthMinimum);
  }

  Widget YearChart(Size size, List<_ChartData> data) {
    return Chart(size, data, yearMinimum);
  }

  Widget TenYearChart(Size size, List<_ChartData> data) {
    return Chart(size, data, tenYearMinimum);
  }

  Widget Stockinfo(Size size, String stockName, String stockCode,
      var stockPrice, var stockPerc, var stockChange) {
    stockPrice = intlprice.format(stockPrice);
    stockPerc = intlperc.format(stockPerc) + "%";

    if (stockName != "코스피" &&
        stockName != "코스닥" &&
        stockName != "다우존스" &&
        stockName != "나스닥" &&
        stockName != "닛케이") {
      stockChange = intlprice.format(stockChange.abs());
    } else {
      stockChange = stockChange.abs();
    }

    String stockChangeIcon;
    if (stockColor == CHART_PLUS) {
      stockChangeIcon = "▲";
    } else if (stockColor == CHART_MINUS) {
      stockChangeIcon = "▼";
    } else {
      stockChangeIcon = "-";
    }
    return Container(
      padding: EdgeInsets.all(size.width * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                //Firebase 적용사항
                stockName,
                textAlign: TextAlign.justify,
                style: TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 1),
                  fontSize: size.width * 0.06,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              SizedBox(width: size.width * 0.01),
              Text(
                //Firebase 적용사항
                stockCode,
                style: TextStyle(
                    color: Colors.grey[700], fontSize: size.width * 0.04),
              )
            ],
          ),
          SizedBox(height: size.height * 0.01),
          Row(
            children: [
              Text(
                //Firebase 적용사항
                stockPrice.toString(),
                style: TextStyle(
                  color: stockColor,
                  fontSize: size.width * 0.06,
                  letterSpacing: 0,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Container(
                margin: EdgeInsets.only(left: size.width * 0.02),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: size.width * 0.01),
                      child: Text(
                        //Firebase 적용사항
                        stockChangeIcon,
                        style: TextStyle(
                          color: stockColor,
                          fontSize: size.width * 0.03,
                          letterSpacing: 0,
                          fontWeight: FontWeight.normal,
                          // height: 3,
                        ),
                      ),
                    ),
                    Text(
                      //Firebase 적용사항
                      "${stockChange.toString()} (${stockPerc.toString()})",
                      style: TextStyle(
                        color: stockColor,
                        fontSize: size.width * 0.035,
                        letterSpacing: 0,
                        fontWeight: FontWeight.normal,
                        // height: 3,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  // 하단 위젯 구성
  Widget newsInfo(
      Size size, String msg, Map<String, dynamic> firebaseStockData) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        color: Colors.white,
      ),
      width: size.width * 0.9,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            SizedBox(
              height: size.height * 0.02,
            ),
            ListView.separated(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              itemCount: newsDataList.length,
              itemBuilder: (BuildContext context, int index) {
                return stockNews(
                    size,
                    newsDataList[index]["title"],
                    newsDataList[index]["date"].substring(0, 16),
                    newsDataList[index]["label"],
                    newsDataList[index]["url"]);
              },
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(color: GREY),
            ),
            SizedBox(
              height: size.height * 0.02,
            )
          ],
        ),
      ),
    );
  }

  Widget stockInfo(
      Size size, String msg, Map<String, dynamic> firebaseStockData) {
    List<String> stockInfo = <String>[
      'TimePerPositiveNewsCount',
      'TimePerNegativeNewsCount',
      'stockClosingPrice',
      'stockHighPrice',
      'stockLowPrice',
      'stockVolume',
      'marketCap',
    ];
    List<String> stockInfodetail = <String>[
      '시간당 긍정 기사 개수',
      '시간당 부정 기사 개수',
      '전일종가',
      '고가',
      '저가',
      '거래량',
      '시가총액',
    ];
    if (firebaseStockData["stockName"] == "코스피" ||
        firebaseStockData["stockName"] == "코스닥" ||
        firebaseStockData["stockName"] == "다우존스" ||
        firebaseStockData["stockName"] == "나스닥" ||
        firebaseStockData["stockName"] == "닛케이") {
      stockInfo.removeLast();
      stockInfodetail.removeLast();
    }

    List<String> stockValue = [];

    for (var element in stockInfo) {
      if (element == "marketCap") {
        stockValue.add("${marketCapFormat(firebaseStockData[element])}원");
      } else {
        print(element);
        stockValue.add(intlprice.format(firebaseStockData[element]));
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        color: Colors.white,
      ),
      width: size.width * 0.9,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            SizedBox(
              height: size.height * 0.02,
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
              itemCount: stockInfo.length,
              itemBuilder: (BuildContext context, int index) {
                return stockdetail(size, stockInfo[index],
                    stockInfodetail[index], stockValue[index]);
              },
              separatorBuilder: (BuildContext context, int index) =>
                  const Divider(color: GREY),
            ),
            SizedBox(
              height: size.height * 0.02,
            )
          ],
        ),
      ),
    );
  }

  Widget stockdetail(Size size, String Iconlist, String Infodetail, var Value) {
    return Container(
      margin: EdgeInsets.only(
          bottom: size.height * 0.012, top: size.height * 0.012),
      child: Row(
        children: [
          //Firebase 적용사항
          Icon(Icons.check_box_outlined),
          SizedBox(width: size.width * 0.02),
          Text(
            Infodetail,
            textAlign: TextAlign.left,
            style: TextStyle(
                color: Color.fromRGBO(91, 99, 106, 1),
                fontSize: size.width * 0.04,
                letterSpacing: 0,
                fontWeight: FontWeight.bold,
                height: 1),
          ),
          Expanded(
            child: Text(
              Value.toString(),
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 1.0),
                  fontSize: size.width * 0.036,
                  letterSpacing: 0,
                  fontWeight: FontWeight.normal,
                  height: 1),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _launchInWebViewOrVC(Uri url) async {
    if (!await launchUrl(
      url,
      mode: LaunchMode.inAppWebView,
      webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: false,
          headers: <String, String>{'my_header_key': 'my_header_value'}),
    )) {
      throw 'Could not launch $url';
    }
  }

  Widget stockNews(
      Size size, String title, String content, String result, String url) {
    // String? 에러
    if (title == null) {
      return SizedBox();
    }

    Uri uri = Uri.parse(url);

    return GestureDetector(
      onTap: () async {
        await _launchInWebViewOrVC(uri);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.only(top: size.height * 0.004),
                width: size.width * 0.7,
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  // style: TextStyle(
                  //     // fontWeight: FontWeight.bold,
                  //     fontSize: size.height * 0.02),
                ),
              ),
              newsResult(result),
            ],
          ),
          SizedBox(
            height: size.height * 0.03,
          ),
          Text(
            content,
            maxLines: 2,
            textAlign: TextAlign.start,
            style: TextStyle(
                fontWeight: FontWeight.normal, color: Color(0xff888888)),
          ),
          SizedBox(
            height: size.height * 0.004,
          ),
        ],
      ),
      behavior: HitTestBehavior.opaque,
    );
  }

  Widget newsResult(String result) {
    var resultColor;
    var resultBackgrouncolor;
    if (result == null) {
      return Container();
    }
    if (result == "2") {
      resultColor = Color(0xff0EBD8D);
      resultBackgrouncolor = Color(0xffE7F9F4);
    } else if (result == "0") {
      resultColor = Color(0xffEF3641);
      resultBackgrouncolor = Color(0xffF9E7E7);
    } else {
      resultColor = GREY;
      resultBackgrouncolor = Color.fromARGB(255, 185, 185, 185);
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: resultBackgrouncolor,
      ),
      child: Text(
        (result == "0" ? "악재" : (result == "2" ? "호재" : "중립")),
        style: TextStyle(
          color: resultColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: StockscreenBar(
          context, widget.stockName, widget.stockName, widget.stockCode),
      body: SafeArea(
        child: FutureBuilder(
          future: getStockInfo(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.hasData) {
              firebaseStockData = snapshot.data;
              if (firebaseStockData["stockPerChange"] > 0) {
                stockColor = CHART_PLUS;
              } else if (firebaseStockData["stockPerChange"] < 0) {
                stockColor = CHART_MINUS;
              } else if (firebaseStockData["stockPerChange"] == 0) {
                stockColor = Color.fromARGB(255, 120, 119, 119);
              }
              return FutureBuilder(
                // 종목명 - 상위 클래스에서 받아와야함
                future: chartInit(firebaseStockData["stockCode"]),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          Stockmain(size),
                          infoTab(size, firebaseStockData),
                        ],
                      ),
                    );
                  } else {
                    return Center(child: indicator());
                  }
                },
              );
            } else {
              return Center(child: indicator());
            }
          },
        ),
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);

  final DateTime x;
  final double y;
}
