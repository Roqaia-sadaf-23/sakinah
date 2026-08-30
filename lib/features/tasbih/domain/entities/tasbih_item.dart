class TasbihItem {
  const TasbihItem({required this.text, required this.target});

  final String text;
  final int target;
}

const tasbihSequence = <TasbihItem>[
  TasbihItem(text: 'سبحان الله', target: 33),
  TasbihItem(text: 'الحمد لله', target: 33),
  TasbihItem(text: 'الله أكبر', target: 33),
  TasbihItem(
    text:
        'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد، وهو على كل شيء قدير',
    target: 1,
  ),
];
