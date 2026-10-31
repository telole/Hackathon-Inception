import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PkLogo extends StatelessWidget {
  const PkLogo({super.key, this.width = 180, this.height, this.onDark = false});

  final double width;
  final double? height;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Pakaiankita',
      child: SvgPicture.asset(
        onDark
            ? 'assets/logo/3-pakaiankita-latar-gelap.svg'
            : 'assets/logo/1-pakaiankita-logo-utama.svg',
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}

class PkLogoMark extends StatelessWidget {
  const PkLogoMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Ikon Pakaiankita',
      child: SvgPicture.asset(
        'assets/logo/2-pakaiankita-ikon-aplikasi.svg',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
