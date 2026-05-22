import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const appPrimaryPurple = Color(0xFF7B4FD8);
const appSecondaryBlue = Color(0xFF5FB5FF);
const appScaffoldLavender = Color(0xFFF8F2FF);
const appSurface = Color(0xFFFFFBFF);
const appBlush = Color(0xFFFFEEF8);
const appSoftBlue = Color(0xFFEAF7FF);
const appBorder = Color(0xFFE7D9FF);
const appText = Color(0xFF2B2140);
const appName = 'Гороскоп Niami';
const appDisplayFont = 'serif';
const appBodyFont = 'sans-serif';

void main() {
  // Старт приложения: создаем главный экран и даем ему объект для общения с backend.
  runApp(NiamiHoroscopeApp(api: HoroscopeApi()));
}

class HoroscopeProfile {
  // Анкета пользователя. Из этих полей backend делает персональный гороскоп.
  const HoroscopeProfile({
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.familyStatus,
    required this.location,
    required this.children,
    required this.workStatus,
    required this.workDetails,
  });

  final String name;
  final String birthDate;
  final String gender;
  final String familyStatus;
  final String location;
  final String children;
  final String workStatus;
  final String workDetails;

  Map<String, dynamic> toJson() {
    // Превращаем анкету в JSON с такими же именами полей, как ждет Python backend.
    return {
      'name': name,
      'birth_date': birthDate,
      'gender': gender,
      'family_status': familyStatus,
      'location': location,
      'children': children,
      'work_status': workStatus,
      'work_details': workDetails,
    };
  }
}

class FreeHoroscope {
  // Данные для бесплатного экрана: короткий текст и список того, что откроется за 49 рублей.
  const FreeHoroscope({
    required this.date,
    required this.horoscope,
    required this.offerPriceRub,
    required this.includedSections,
  });

  final String date;
  final String horoscope;
  final int offerPriceRub;
  final List<String> includedSections;

  factory FreeHoroscope.fromJson(Map<String, dynamic> json) {
    // Превращаем JSON от backend в удобный Dart-объект.
    return FreeHoroscope(
      date: json['date'] as String,
      horoscope: json['horoscope'] as String,
      offerPriceRub: json['offer_price_rub'] as int,
      includedSections: (json['included_sections'] as List<dynamic>)
          .cast<String>(),
    );
  }
}

class FullHoroscope {
  // Данные для полного экрана: несколько больших разделов гороскопа.
  const FullHoroscope({required this.date, required this.sections});

  final String date;
  final Map<String, String> sections;

  factory FullHoroscope.fromJson(Map<String, dynamic> json) {
    // Backend присылает sections как JSON-объект, а Flutter хранит его как Map<String, String>.
    final rawSections = json['sections'] as Map<String, dynamic>;
    return FullHoroscope(
      date: json['date'] as String,
      sections: rawSections.map((key, value) => MapEntry(key, value as String)),
    );
  }
}

abstract class HoroscopeApiClient {
  // Такой интерфейс упрощает тесты: можно подставить фейковый API вместо настоящего сервера.
  Future<FreeHoroscope> fetchFree(HoroscopeProfile profile);
  Future<FullHoroscope> fetchFull(HoroscopeProfile profile);
}

class HoroscopeApi implements HoroscopeApiClient {
  // baseUrl - адрес nginx/backend. Сейчас nginx добавляет перед API путь /horoscope.
  HoroscopeApi({String? baseUrl, http.Client? client})
    : baseUrl =
          baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'https://horoscope.niami.ru',
            ),
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  @override
  Future<FreeHoroscope> fetchFree(HoroscopeProfile profile) async {
    // Просим backend сделать бесплатный гороскоп по анкете.
    final response = await _post('/horoscope/free', profile);
    return FreeHoroscope.fromJson(response);
  }

  @override
  Future<FullHoroscope> fetchFull(HoroscopeProfile profile) async {
    // Просим backend сделать полную версию по той же анкете.
    final response = await _post('/horoscope/full', profile);
    return FullHoroscope.fromJson(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    HoroscopeProfile profile,
  ) async {
    // Здесь реально происходит HTTP-запрос: анкета уходит на сервер, ответ приходит JSON.
    final uri = Uri.parse('$baseUrl$path');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(profile.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Сервер вернул ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}

class NiamiHoroscopeApp extends StatelessWidget {
  const NiamiHoroscopeApp({super.key, required this.api});

  final HoroscopeApiClient api;

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: appPrimaryPurple,
      onPrimary: Colors.white,
      secondary: appSecondaryBlue,
      onSecondary: appText,
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: appSurface,
      onSurface: appText,
    );
    final baseTextTheme = ThemeData.light(useMaterial3: true).textTheme;
    final niamiTextTheme = baseTextTheme
        .apply(
          fontFamily: appBodyFont,
          bodyColor: appText,
          displayColor: appText,
        )
        .copyWith(
          headlineSmall: baseTextTheme.headlineSmall?.copyWith(
            fontFamily: appDisplayFont,
            color: appText,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontFamily: appDisplayFont,
            color: appText,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
          titleMedium: baseTextTheme.titleMedium?.copyWith(
            fontFamily: appDisplayFont,
            color: appText,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
          labelLarge: baseTextTheme.labelLarge?.copyWith(
            fontFamily: appBodyFont,
            fontWeight: FontWeight.w800,
          ),
        );
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: appScaffoldLavender,
        useMaterial3: true,
        fontFamily: appBodyFont,
        fontFamilyFallback: const [appDisplayFont, 'Roboto'],
        textTheme: niamiTextTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: appScaffoldLavender,
          foregroundColor: appText,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: appText,
            fontFamily: appDisplayFont,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: appBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: appBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: appPrimaryPurple, width: 1.6),
          ),
          filled: true,
          fillColor: appSurface,
          prefixIconColor: appPrimaryPurple,
          suffixIconColor: appPrimaryPurple,
          labelStyle: const TextStyle(color: Color(0xFF68557F)),
        ),
        cardTheme: CardThemeData(
          color: appSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: appBorder),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: appPrimaryPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: appPrimaryPurple,
            side: const BorderSide(color: appPrimaryPurple),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: appPrimaryPurple),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: appSoftBlue,
          side: const BorderSide(color: Color(0xFFCDEBFF)),
          labelStyle: const TextStyle(
            color: appText,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      home: HoroscopeHome(api: api),
    );
  }
}

class HoroscopeHome extends StatefulWidget {
  const HoroscopeHome({super.key, required this.api});

  final HoroscopeApiClient api;

  @override
  State<HoroscopeHome> createState() => _HoroscopeHomeState();
}

class _HoroscopeHomeState extends State<HoroscopeHome> {
  // Эти переменные решают, какой экран показывать: анкету, бесплатный или полный прогноз.
  HoroscopeProfile? _profile;
  FreeHoroscope? _free;
  FullHoroscope? _full;
  bool _loading = false;
  bool _loadingFull = false;
  String? _error;

  Future<void> _generateFree(HoroscopeProfile profile) async {
    // Пользователь нажал кнопку в анкете: сохраняем профиль и просим бесплатный прогноз.
    setState(() {
      _profile = profile;
      _loading = true;
      _error = null;
      _free = null;
      _full = null;
    });
    try {
      final result = await widget.api.fetchFree(profile);
      setState(() => _free = result);
    } catch (_) {
      setState(
        () => _error =
            'Не удалось получить гороскоп. Проверьте backend и попробуйте еще раз.',
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _unlockFull() async {
    // Пользователь нажал "Купить": оплаты пока нет, мы сразу просим полный прогноз.
    final profile = _profile;
    if (profile == null) return;

    setState(() {
      _loadingFull = true;
      _error = null;
    });
    try {
      final result = await widget.api.fetchFull(profile);
      setState(() => _full = result);
    } catch (_) {
      setState(
        () => _error =
            'Не удалось открыть полную версию. Нажмите кнопку еще раз.',
      );
    } finally {
      if (mounted) {
        setState(() => _loadingFull = false);
      }
    }
  }

  void _reset() {
    // Возврат в начало: очищаем анкету и оба результата.
    setState(() {
      _profile = null;
      _free = null;
      _full = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Простая логика экранов: если есть полный прогноз - показываем его, иначе бесплатный, иначе анкету.
    Widget body;
    if (_full != null) {
      body = FullHoroscopeScreen(full: _full!, onReset: _reset);
    } else if (_free != null) {
      body = FreeHoroscopeScreen(
        free: _free!,
        loadingFull: _loadingFull,
        onUnlock: _unlockFull,
        onReset: _reset,
      );
    } else {
      body = ProfileFormScreen(loading: _loading, onSubmit: _generateFree);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(appName),
        centerTitle: false,
        actions: [
          if (_free != null || _full != null)
            IconButton(
              tooltip: 'Новая анкета',
              onPressed: _reset,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ErrorBanner(message: _error!),
              ),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      appScaffoldLavender,
                      Color(0xFFEAF7FF),
                      Color(0xFFFFF7FC),
                    ],
                  ),
                ),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileFormScreen extends StatefulWidget {
  // Экран анкеты собирает данные и отдает готовый HoroscopeProfile наверх.
  const ProfileFormScreen({
    super.key,
    required this.loading,
    required this.onSubmit,
  });

  final bool loading;
  final ValueChanged<HoroscopeProfile> onSubmit;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  // Контроллеры хранят текст, который пользователь вводит в поля.
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _birthDate = TextEditingController();
  final _location = TextEditingController();
  final _children = TextEditingController();
  final _workDetails = TextEditingController();

  String _gender = 'Мужчина';
  String _familyStatus = 'Женат / замужем';
  String _workStatus = 'Работает в найме';

  @override
  void dispose() {
    // Когда экран исчезает, освобождаем контроллеры, чтобы приложение не держало лишнюю память.
    _name.dispose();
    _birthDate.dispose();
    _location.dispose();
    _children.dispose();
    _workDetails.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                Text(
                  'Анкета для прогноза',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: appText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Заполните данные, чтобы получить бесплатный общий гороскоп и открыть полную версию за 49 ₽.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF695D7C),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('nameField'),
                  controller: _name,
                  textCapitalization:TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[а-яА-ЯёЁa-zA-Z\s-]')),
  ],
                  decoration: const InputDecoration(
                    labelText: 'Имя',
                    hintText: 'Фио',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => _required(value, 'Введите имя'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('birthDateField'),
                  controller: _birthDate,
                  keyboardType: TextInputType.datetime,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Дата рождения',
                    hintText: 'ГГГГ-ММ-ДД',
                    helperText:'год,месяц,день',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    suffixIcon: IconButton(
                      tooltip: 'Выбрать дату',
                      icon: const Icon(Icons.calendar_month),
                      onPressed: _pickBirthDate,
                    ),
                  ),
                  validator: _validateDate,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Пол',
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Мужчина', child: Text('Мужчина')),
                    DropdownMenuItem(value: 'Женщина', child: Text('Женщина')),
                    DropdownMenuItem(value: 'Другое', child: Text('Другое')),
                  ],
                  onChanged: (value) =>
                      setState(() => _gender = value ?? _gender),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _familyStatus,
                  decoration: const InputDecoration(
                    labelText: 'Семейный статус',
                    prefixIcon: Icon(Icons.favorite_border),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Не в отношениях',
                      child: Text('Не в отношениях'),
                    ),
                    DropdownMenuItem(
                      value: 'В отношениях',
                      child: Text('В отношениях'),
                    ),
                    DropdownMenuItem(
                      value: 'Женат / замужем',
                      child: Text('Женат / замужем'),
                    ),
                    DropdownMenuItem(
                      value: 'Разведен / разведена',
                      child: Text('Разведен / разведена'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _familyStatus = value ?? _familyStatus),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('locationField'),
                  controller: _location,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Город или часовой пояс',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: (value) =>
                      _required(value, 'Введите город или часовой пояс'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('childrenField'),
                  controller: _children,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Дети',
                    hintText: 'Например: 4 дочери или детей нет',
                    prefixIcon: Icon(Icons.family_restroom),
                  ),
                  validator: (value) =>
                      _required(value, 'Опишите наличие детей'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _workStatus,
                  decoration: const InputDecoration(
                    labelText: 'Стиль занятости',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Работает в найме',
                      child: Text('Работает в найме'),
                    ),
                    DropdownMenuItem(
                      value: 'Предприниматель',
                      child: Text('Предприниматель'),
                    ),
                    DropdownMenuItem(
                      value: 'Фрилансер',
                      child: Text('Фрилансер'),
                    ),
                    DropdownMenuItem(
                    value:'Учеба',
                      child: Text('Учеба'),
                    ),
                    DropdownMenuItem(
                      value: 'Не работает',
                      child: Text('Не работает'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _workStatus = value ?? _workStatus),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('workDetailsField'),
                  controller: _workDetails,
                  minLines: 2,
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Работа или бизнес',
                    hintText: 'Сфера, роль, команда, бизнес-задачи',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  validator: (value) =>
                      _required(value, 'Опишите работу или бизнес'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('submitProfile'),
                onPressed: widget.loading ? null : _submit,
                icon: widget.loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(
                  widget.loading
                      ? 'Готовлю прогноз'
                      : 'Получить бесплатный гороскоп',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  String? _validateDate(String? value) {
    final trimmed = value?.trim() ?? '';
    final farset = DateTime.tryParse(trimmed);
    if (trimmed.isEmpty || DateTime.tryParse(trimmed) == null) {
      return 'Введите дату в формате ГГГГ-ММ-ДД';
    }
    if (farset!.isAfter(DateTime.now())){
      return 'Нельзя поставить дату рождения в будущем';
    }
    return null;
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    _birthDate.text = picked.toIso8601String().substring(0, 10);
  }

  void _submit() {
    // Если все поля заполнены правильно, собираем анкету и запускаем получение гороскопа.
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    widget.onSubmit(
      HoroscopeProfile(
        name: _name.text.trim(),
        birthDate: _birthDate.text.trim(),
        gender: _gender,
        familyStatus: _familyStatus,
        location: _location.text.trim(),
        children: _children.text.trim(),
        workStatus: _workStatus,
        workDetails: _workDetails.text.trim(),
      ),
    );
  }
}

class FreeHoroscopeScreen extends StatelessWidget {
  // Экран бесплатного результата показывает короткий прогноз и кнопку открытия полной версии.
  const FreeHoroscopeScreen({
    super.key,
    required this.free,
    required this.loadingFull,
    required this.onUnlock,
    required this.onReset,
  });

  final FreeHoroscope free;
  final bool loadingFull;
  final VoidCallback onUnlock;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        ResultHeader(
          eyebrow: 'Бесплатная версия',
          title: 'Общий гороскоп',
          subtitle: 'Дата прогноза: ${free.date}',
          icon: Icons.nights_stay_outlined,
        ),
        const SizedBox(height: 12),
        TextCard(text: free.horoscope),
        const SizedBox(height: 16),
        Text(
          'В развернутой версии',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: appText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final section in free.includedSections)
              Chip(
                avatar: const Icon(Icons.lock_open, size: 16),
                label: Text(section),
              ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: loadingFull ? null : onUnlock,
          icon: loadingFull
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.payments_outlined),
          label: Text(
            loadingFull
                ? 'Открываю полную версию'
                : 'Купить за ${free.offerPriceRub} ₽',
          ),
        ),
        TextButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Изменить анкету'),
        ),
      ],
    );
  }
}

class FullHoroscopeScreen extends StatelessWidget {
  // Экран полной версии показывает каждый раздел отдельной карточкой.
  const FullHoroscopeScreen({
    super.key,
    required this.full,
    required this.onReset,
  });

  final FullHoroscope full;
  final VoidCallback onReset;

  static const _titles = {
    'general': 'Общий гороскоп',
    'romantic': 'Романтический гороскоп',
    'family_children': 'Семья и дети',
    'work': 'Рабочий гороскоп',
    'business_money': 'Бизнес и деньги',
    'party': 'Тусовочный гороскоп',
  };

  static const _icons = {
    'general': Icons.auto_awesome,
    'romantic': Icons.favorite_border,
    'family_children': Icons.family_restroom,
    'work': Icons.work_outline,
    'business_money': Icons.account_balance_wallet_outlined,
    'party': Icons.local_bar_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        ResultHeader(
          eyebrow: 'Полная версия',
          title: 'Развернутый гороскоп',
          subtitle: 'Дата прогноза: ${full.date}',
          icon: Icons.workspace_premium_outlined,
        ),
        const SizedBox(height: 12),
        for (final entry in _titles.entries)
          SectionCard(
            title: entry.value,
            text: full.sections[entry.key] ?? '',
            icon: _icons[entry.key] ?? Icons.auto_awesome,
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Составить новый прогноз'),
        ),
      ],
    );
  }
}

class ResultHeader extends StatelessWidget {
  const ResultHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1E8FF), Color(0xFFE4F5FF), appBlush],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A7B4FD8),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white),
            ),
            child: Icon(
              icon,
              size: 26,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TextCard extends StatelessWidget {
  const TextCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: appText, height: 1.45),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: appSoftBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: appText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF403550),
                height: 1.38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEF4),
        border: Border.all(color: const Color(0xFFFFB5CF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFA84817)),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
