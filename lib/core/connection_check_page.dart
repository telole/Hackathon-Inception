import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

/// Layar sementara untuk memastikan aplikasi tersambung ke Supabase.
/// Hapus setelah layar login/beranda sungguhan dibuat.
class ConnectionCheckPage extends StatefulWidget {
  const ConnectionCheckPage({super.key});

  @override
  State<ConnectionCheckPage> createState() => _ConnectionCheckPageState();
}

class _ConnectionCheckPageState extends State<ConnectionCheckPage> {
  bool _loading = true;
  bool _connected = false;
  String _message = 'Memeriksa koneksi...';

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() {
      _loading = true;
      _message = 'Memeriksa koneksi...';
    });

    try {
      // Tabel ini sengaja tidak ada. Jika server membalas "tabel tidak
      // ditemukan", berarti URL dan key valid dan server terjangkau.
      await Supabase.instance.client.from('_ping').select().limit(1);
      _setResult(true, 'Tersambung ke Supabase.');
    } on PostgrestException catch (e) {
      final tableMissing = e.code == 'PGRST205' || e.code == '42P01';
      if (tableMissing) {
        _setResult(true, 'Tersambung ke Supabase (server membalas).');
      } else {
        _setResult(false, 'Server menolak: ${e.code} ${e.message}');
      }
    } catch (e) {
      _setResult(false, 'Gagal tersambung: $e');
    }
  }

  void _setResult(bool connected, String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _connected = connected;
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = _connected ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: const Text('Cek Koneksi Supabase')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loading)
                const CircularProgressIndicator()
              else
                Icon(
                  _connected ? Icons.check_circle : Icons.error,
                  color: color,
                  size: 72,
                ),
              const SizedBox(height: 16),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                Env.supabaseUrl,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _loading ? null : _check,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}