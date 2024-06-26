import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('AC Controller'),
        ),
        body: ControlPanel(),
      ),
    );
  }
}

class ControlPanel extends StatefulWidget {
  @override
  _ControlPanelState createState() => _ControlPanelState();
}

class _ControlPanelState extends State<ControlPanel> {
  final String baseUrl = 'http://192.168.1.110';  // 替换为你的ESP8266的IP地址
  String temperature = 'Loading...';
  String fan = 'Loading...';
  int offTimerHours = 0, offTimerMinutes = 0;

  @override
  void initState() {
    super.initState();
    fetchTemperature();
    fetchFan();
  }

  Future<void> sendRequest(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl/$endpoint'));

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success: ${response.body}')),
      );
      if (endpoint == 'temp-up' || endpoint == 'temp-down') {
          fetchTemperature(); // 更新温度显示
      }
      if (endpoint == 'fan-up' || endpoint == 'fan-down') {
          fetchFan(); // 更新温度显示
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to communicate with server')),
      );
    }
  }

  Future<void> fetchTemperature() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get-temp'));
      if (response.statusCode == 200) {
        setState(() {
          temperature = response.body;
        });
      } else {
        setState(() {
          temperature = 'Error';
        });
      }
    } catch (e) {
      setState(() {
        // temperature = 'Error: $e';
        temperature = '';
      });
    }
  }

  Future<void> fetchFan() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get-fan'));
      if (response.statusCode == 200) {
        setState(() {
          fan = response.body;
        });
      } else {
        setState(() {
          fan = 'Error';
        });
      }
    } catch (e) {
      setState(() {
        fan = '';
      });
    }
  }

  Future<void> sendOffTimer(int hour, int minute) async {
    print("Hour: $hour, Minute: $minute");

    final response = await http.get(Uri.parse('$baseUrl/set-off-timer?hour=$hour&minute=$minute'));

    if (response.statusCode == 200) {
      // print('Number sent successfully: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success: ${response.body}')),
      );
    } else {
      print('Failed to send number');
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double tmpBtnWidth = screenWidth * 0.5;
    double fanBtnWidth = screenWidth * 0.25;
    double setOffTimerWidth = screenWidth * 0.25;
    // final TextEditingController _hoursController = TextEditingController();
    // final TextEditingController _minutesController = TextEditingController();

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            flex: 1, // 按比例分配空间
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Fan: \n$fan',
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: fanBtnWidth, // 固定宽度
                  child: ElevatedButton(
                    onPressed: () => sendRequest('fan-up'),
                    child: Icon(Icons.arrow_upward),
                  )
                ),
                SizedBox(
                  width: fanBtnWidth, // 固定宽度
                  child: ElevatedButton(
                    onPressed: () => sendRequest('fan-down'),
                    child: Icon(Icons.arrow_downward),
                  )
                ),
              ],
            ),
          ),
          
          SizedBox(width: 10), 
          
          Flexible(
            flex: 2, // 按比例分配空间
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Temperature: \n$temperature°C',
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                SizedBox(
                  width: tmpBtnWidth, // 固定宽度
                  child: ElevatedButton(
                    onPressed: () => sendRequest('on-off'),
                    child: Text('Turn ON / OFF'),
                  ),
                ),
                SizedBox(height: 30), // 增加间距
                SizedBox(
                  width: tmpBtnWidth, // 固定宽度
                  child: ElevatedButton.icon(
                    onPressed: () => sendRequest('temp-up'),
                    icon: Icon(Icons.arrow_upward),
                    label: Text('Increase'),
                  ),
                ),
                SizedBox(
                  width: tmpBtnWidth, // 固定宽度
                  child: ElevatedButton.icon(
                    onPressed: () => sendRequest('temp-down'),
                    icon: Icon(Icons.arrow_downward),
                    label: Text('Decrease'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10), 

          Flexible(
            flex: 1, // 按比例分配空间
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Off After: \n',
                  style: TextStyle(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  width: setOffTimerWidth,
                  child: Column(
                    children: [
                      TextField(
                        // controller: _hoursController,
                        decoration: const InputDecoration(
                          labelText: 'Hours',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                          FilteringTextInputFormatter.allow(RegExp(r'^([01]?[0-9]|2[0-3])$')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            if (value.isNotEmpty) {
                              offTimerHours = int.parse(value);
                            } else {
                              offTimerHours = 0;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        // controller: _minutesController,
                        decoration: const InputDecoration(
                          labelText: 'Minutes',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                          FilteringTextInputFormatter.allow(RegExp(r'^[0-5]?[0-9]$')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            if (value.isNotEmpty) {
                              offTimerMinutes = int.parse(value);
                            } else {
                              offTimerMinutes = 0;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => sendOffTimer(offTimerHours, offTimerMinutes),
                        child: const Text('Set'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      /*
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Current Temperature: \n$temperature°C',
            style: TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          SizedBox(
            width: 200, // 固定宽度
            child: ElevatedButton(
              onPressed: () => sendRequest('on-off'),
              child: Text('Turn ON / OFF AC'),
            ),
          ),
          SizedBox(height: 30), // 增加间距
          SizedBox(
            width: 200, // 固定宽度
            child: ElevatedButton.icon(
              onPressed: () => sendRequest('temp-up'),
              icon: Icon(Icons.arrow_upward),
              label: Text('Increase'),
            ),
          ),
          SizedBox(
            width: 200, // 固定宽度
            child: ElevatedButton.icon(
              onPressed: () => sendRequest('temp-down'),
              icon: Icon(Icons.arrow_downward),
              label: Text('Decrease'),
            ),
          ),
        ],
      ),
      */
    );
  }
}



/*
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
*/