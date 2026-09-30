import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const GoldBotApp());
}

class GoldBotApp extends StatelessWidget {
  const GoldBotApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gold Scalp & Swing Bot',
      theme: ThemeData(
        primarySwatch: Colors.amber,
        brightness: Brightness.dark,
      ),
      home: const LoginScreen(),
    );
  }
}

// 1. شاشة تسجيل الدخول للحساب الحقيقي
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _accountIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serverController = TextEditingController();

  void _connectAccount() {
    String accountId = _accountIdController.text.trim();
    String password = _passwordController.text.trim();
    String server = _serverController.text.trim();

    if (accountId.isEmpty || password.isEmpty || server.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال بيانات الحساب الحقيقي كاملاً')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TradingDashboard(
          accountId: accountId,
          password: password,
          server: server,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل دخول Exness الحقيقي'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.show_chart, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              const Text(
                'بوت الذهب: سكالبينغ وسوينغ (XAUUSD)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _accountIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رقم الحساب (Account ID)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة مرور التداول (Password)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.key),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _serverController,
                decoration: const InputDecoration(
                  labelText: 'اسم السيرفر (Server Name)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dns),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  onPressed: _connectAccount,
                  child: const Text(
                    'ربط وتشغيل الروبوت',
                    style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 2. لوحة التحكم وتحليل استراتيجيات السكالبينغ والسوينغ
class TradingDashboard extends StatefulWidget {
  final String accountId;
  final String password;
  final String server;

  const TradingDashboard({
    Key? key,
    required this.accountId,
    required this.password,
    required this.server,
  }) : super(key: key);

  @override
  _TradingDashboardState createState() => _TradingDashboardState();
}

class _TradingDashboardState extends State<TradingDashboard> {
  String _connectionStatus = 'جاري الاتصال بخادم التداول...';
  String _scalpSignal = 'تحليل السكالبينغ السريع...';
  String _swingSignal = 'تحليل السوينغ الكبير...';
  Color _scalpColor = Colors.orange;
  Color _swingColor = Colors.orange;
  double _goldPrice = 0.0;
  double _previousPrice = 0.0;
  Timer? _priceTimer;

  @override
  void initState() {
    super.initState();
    _startLiveMarketMonitor();
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    super.dispose();
  }

  void _startLiveMarketMonitor() {
    fetchGoldPriceAndAnalyze();
    _priceTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchGoldPriceAndAnalyze();
    });
  }

  Future<void> fetchGoldPriceAndAnalyze() async {
    try {
      final response = await http.get(
        Uri.parse('https://mt-client-api-v1.agiliumtrade.ai/users/current/accounts/${widget.accountId}/symbols/XAUUSD/price'),
        headers: {'auth-token': widget.password},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double currentBid = (data['bid'] ?? 0.0).toDouble();

        setState(() {
          _connectionStatus = 'متصل بالسيرفر: ${widget.server}';
          if (_goldPrice > 0) {
            _previousPrice = _goldPrice;
          }
          _goldPrice = currentBid;
          
          // تحليل استراتيجيات التداول (سكالبينغ وسوينغ)
          _evaluateStrategies();
        });
      } else {
        setState(() {
          _connectionStatus = 'خطأ في المصادقة مع المنصة (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'فشل الاتصال بالشبكة';
      });
    }
  }

  void _evaluateStrategies() {
    if (_previousPrice == 0.0) return;
    double change = _goldPrice - _previousPrice;

    setState(() {
      // إستراتيجية السكالبينغ (أهداف سريعة بناءً على التغير اللحظي)
      if (change >= 0.2) {
        _scalpSignal = 'سكالبينغ: فرصة شراء سريعة (BUY)';
        _scalpColor = Colors.green;
      } else if (change <= -0.2) {
        _scalpSignal = 'سكالبينغ: فرصة بيع سريعة (SELL)';
        _scalpColor = Colors.red;
      } else {
        _scalpSignal = 'سكالبينغ: انتظار فرصة ملائمة';
        _scalpColor = Colors.grey;
      }

      // إستراتيجية السوينغ (أهداف متوسطة وطويلة المدى)
      if (change >= 0.5) {
        _swingSignal = 'سوينغ: اتجاه صاعد قوي (BUY SWING)';
        _swingColor = Colors.greenAccent;
      } else if (change <= -0.5) {
        _swingSignal = 'سوينغ: اتجاه هابط قوي (SELL SWING)';
        _swingColor = Colors.redAccent;
      } else {
        _swingSignal = 'سوينغ: تذبذب عرضي، مراقبة الاتجاه';
        _swingColor = Colors.grey;
      }
    });
  }

  Future<void> executeTrade(String actionType, String mode) async {
    setState(() {
      _connectionStatus = 'جاري تنفيذ صفقة $mode ($actionType)...';
    });

    try {
      final response = await http.post(
        Uri.parse('https://mt-client-api-v1.agiliumtrade.ai/users/current/accounts/${widget.accountId}/orders'),
        headers: {
          'auth-token': widget.password,
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'symbol': 'XAUUSD',
          'action': actionType,
          'volume': mode == 'Scalping' ? 0.02 : 0.05, // حجم العقد حسب الاستراتيجية
          'type': 'market',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          _connectionStatus = 'تم تنفيذ صفقة الـ $mode بنجاح في حسابك!';
        });
      } else {
        setState(() {
          _connectionStatus = 'فشل تنفيذ الصفقة: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'خطأ في التنفيذ: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('حساب Exness: ${widget.accountId}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _connectionStatus,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            Text(
              'سعر الذهب (XAUUSD): \$$_goldPrice',
              style: const TextStyle(fontSize: 22, color: Colors.amber, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // صندوق إشارة السكالبينغ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _scalpColor.withOpacity(0.2),
                border: Border.all(color: _scalpColor, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _scalpSignal,
                style: TextStyle(fontSize: 14, color: _scalpColor, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 15),

            // صندوق إشارة السوينغ
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _swingColor.withOpacity(0.2),
                border: Border.all(color: _swingColor, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _swingSignal,
                style: TextStyle(fontSize: 14, color: _swingColor, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),

            const Text('أزرار التداول الآلي / اليدوي:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => executeTrade('ORDER_TYPE_BUY', 'Scalping'),
                  child: const Text('شراء سكالبينغ', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => executeTrade('ORDER_TYPE_SELL', 'Scalping'),
                  child: const Text('بيع سكالبينغ', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  onPressed: () => executeTrade('ORDER_TYPE_BUY', 'Swing'),
                  child: const Text('شراء سوينغ', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                  onPressed: () => executeTrade('ORDER_TYPE_SELL', 'Swing'),
                  child: const Text('بيع سوينغ', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
