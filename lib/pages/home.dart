import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [
    // Band(id: '1', name: 'Metallica', votes: 5),
    // Band(id: '2', name: 'Heroes del Silencio', votes: 3),
    // Band(id: '3', name: 'Bon Jovi', votes: 2),
    // Band(id: '4', name: 'Breaking Benjamin', votes: 10),
  ];

  @override
  void initState() {
    super.initState();

    final socketService = Provider.of<SocketService>(context, listen: false);

    socketService.socket.on('bandas-activas', _handleActiveBands);
  }

  _handleActiveBands(dynamic payload) {
    setState(() {
      this.bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    });
  }

  @override
  void dispose() {
    super.dispose();
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('bandas-activas');
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context, listen: true);

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: Center(
          child: Text('Band names', style: TextStyle(color: Colors.white)),
        ),
        backgroundColor: Colors.blue[700],
        elevation: 3,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            child: socketService.serverStatus == ServerStatus.Online
                ? Icon(Icons.check_circle, color: Colors.blue[300])
                : Icon(Icons.offline_bolt, color: Colors.red),
          ),
        ],
      ),
      body: Column(
        children: [
          _grafica(),
          Expanded(
            child: ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: bands.length,
              itemBuilder: (context, i) => _bandTile(bands[i], socketService),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        elevation: 3,
        onPressed: _addNewBand,
      ),
    );
  }

  Widget _grafica() {
    Map<String, double> dataMap = new Map();

    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });

    final List<Color> colorList = [
      Colors.blue[50],
      Colors.blue[200],
      Colors.pink[50],
      Colors.pink[200],
      Colors.yellow[50],
      Colors.yellow[200],
      Colors.green[50],
      Colors.green[200],
      Colors.purple[50],
      Colors.purple[200],
    ];

    return bands.isEmpty
        ? Container()
        : PieChart(
            dataMap: dataMap,
            animationDuration: Duration(milliseconds: 800),
            colorList: colorList,
            centerText: "",
            chartRadius: double.infinity,
            chartLegendSpacing: 25,
            legendOptions: LegendOptions(
              showLegends: true,
              legendShape: BoxShape.circle,
              legendPosition: LegendPosition.left,
              showLegendsInRow: false,
            ),
            ringStrokeWidth: 50,
            initialAngleInDegree: 0,
            chartType: ChartType.disc,
            chartValuesOptions: ChartValuesOptions(
              chartValueBackgroundColor: Colors.blue[50].withOpacity(0.2),
              showChartValuesInPercentage: true,
              decimalPlaces: 1,
              showChartValueBackground: true,
              showChartValues: true,
            ),
          );
  }

  Widget _bandTile(Band band, SocketService socketService) {
    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => socketService.emit('eliminar-banda', {
        'id': band.id,
      }),
      background: Container(
        color: Colors.red,
        padding: EdgeInsets.only(left: 40.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('Delete Band', style: TextStyle(color: Colors.white)),
        ),
      ),
      child: FadeInLeft(
        duration: Duration(milliseconds: 500),
        child: Container(
          margin: EdgeInsets.all(15),
          padding: EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            boxShadow: [
              BoxShadow(
                blurRadius: 3,
                color: Colors.blue[700],
                spreadRadius: 1.0,
              ),
            ],
          ),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(band.name.substring(0, 2)),
              backgroundColor: Colors.blue[100],
            ),
            title: Text(band.name),
            trailing: Text(
              '${band.votes}',
              style: TextStyle(fontSize: 20),
            ),
            onTap: () => socketService.emit('votar', {
              'id': band.id,
            }),
          ),
        ),
      ),
    );
  }

  void _addNewBand() {
    final textController = new TextEditingController();

    if (Platform.isAndroid) {
      // Android
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('New band name'),
          content: TextField(
            controller: textController,
          ),
          actions: [
            MaterialButton(
              child: Text('Add'),
              elevation: 5,
              textColor: Colors.blue,
              onPressed: () => _addBandToList(textController.text),
            ),
          ],
        ),
      );
    } else {
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text('New band name'),
          content: CupertinoTextField(
            controller: textController,
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('Add'),
              isDefaultAction: true,
              onPressed: () => _addBandToList(textController.text),
            ),
            CupertinoDialogAction(
              child: Text('Dismiss'),
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  void _addBandToList(String name) {
    if (name.length > 1) {
      //Agregamos

      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit('añadir-banda', {
        'name': name,
      });

      // setState(() {
      //   this.bands.add(new Band(
      //         id: DateTime.now().toString(),
      //         name: name,
      //         votes: 0,
      //       ));
      // });
    }

    Navigator.pop(context);
  }
}
