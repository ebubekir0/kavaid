import re

path = r'c:\Users\kul\Desktop\kavaid1111\kavaid\lib\screens\home_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f'Total lines: {len(lines)}')

# header = everything BEFORE slivers list opening (line 1386, index 1385), keep line 1386 (slivers: <Widget>[)
header = lines[:1386]

# footer = from ..._buildMainContentSlivers() onward (line 1922, index 1921)
footer = lines[1921:]

print(f'Header ends at line {len(header)}: {repr(header[-1])}')
print(f'Footer starts at line 1922: {repr(footer[0])}')

sliver_app_bar = r"""                        SliverAppBar(
                          backgroundColor: _isEmsileMode
                              ? (widget.isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFF384D75))
                              : _isQuranMode
                                  ? const Color(0xFF2D4720)
                                  : _isCeviriMode
                                      ? (widget.isDarkMode
                                          ? const Color(0xFF1C1C1E)
                                          : const Color(0xFF1a73e8))
                                      : (widget.isDarkMode
                                          ? const Color(0xFF1C1C1E)
                                          : const Color(0xFF007AFF)),
                          elevation: 0,
                          pinned: true,
                          floating: true,
                          snap: true,
                          toolbarHeight: 0,
                          expandedHeight: 0,
                          bottom: PreferredSize(
                            preferredSize: Size.fromHeight(_isCeviriMode ? 52 : 108),
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: double.infinity,
                                color: _isEmsileMode
                                    ? (widget.isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFF384D75))
                                    : _isQuranMode
                                        ? const Color(0xFF2D4720)
                                        : _isCeviriMode
                                            ? (widget.isDarkMode
                                                ? const Color(0xFF1C1C1E)
                                                : const Color(0xFF1a73e8))
                                            : (widget.isDarkMode
                                                ? const Color(0xFF1C1C1E)
                                                : const Color(0xFF007AFF)),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedSize(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        child: _isCeviriMode
                                            ? const SizedBox(width: double.infinity)
                                            : Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Material(
                                                        color: Colors.transparent,
                                                        child: InkWell(
                                                          onTap: () {
                                                            final auth = AuthService();
                                                            if (!auth.isSignedIn) {
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text('Lutfen once kayit olun, giris yapin.', style: TextStyle(color: Colors.white)),
                                                                  backgroundColor: Colors.black87,
                                                                  duration: Duration(seconds: 2),
                                                                  behavior: SnackBarBehavior.fixed,
                                                                ),
                                                              );
                                                              return;
                                                            }
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) => CustomWordsScreen(isDarkMode: widget.isDarkMode),
                                                              ),
                                                            );
                                                          },
                                                          borderRadius: BorderRadius.circular(10),
                                                          child: Container(
                                                            width: 42,
                                                            height: 42,
                                                            decoration: BoxDecoration(
                                                              color: widget.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                                                              borderRadius: BorderRadius.circular(10),
                                                            ),
                                                            child: Icon(
                                                              Icons.bookmark_rounded,
                                                              color: _isEmsileMode
                                                                  ? const Color(0xFF384D75)
                                                                  : _isQuranMode
                                                                      ? const Color(0xFF4A5729)
                                                                      : const Color(0xFF007AFF),
                                                              size: 24,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Container(
                                                          height: 42,
                                                          decoration: BoxDecoration(
                                                            color: widget.isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                                                            borderRadius: BorderRadius.circular(10),
                                                            border: Border.all(color: Colors.transparent, width: 0.5),
                                                          ),
                                                          child: Row(
                                                            crossAxisAlignment: CrossAxisAlignment.center,
                                                            children: [
                                                              Padding(
                                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                                child: GestureDetector(
                                                                  onLongPress: () {
                                                                    Navigator.of(context).push(
                                                                      MaterialPageRoute(builder: (_) => const LogScreen()),
                                                                    );
                                                                  },
                                                                  child: Icon(
                                                                    Icons.search_rounded,
                                                                    color: widget.isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93),
                                                                    size: 20,
                                                                  ),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: GestureDetector(
                                                                  behavior: HitTestBehavior.opaque,
                                                                  onTap: () {
                                                                    if (_isQuranMode && _isQuranUsageExceeded) return;
                                                                    if (!_searchFocusNode.hasFocus) _searchFocusNode.requestFocus();
                                                                  },
                                                                  child: Container(
                                                                    alignment: Alignment.center,
                                                                    child: TextField(
                                                                      controller: _searchController,
                                                                      focusNode: _searchFocusNode,
                                                                      enabled: !(_isQuranMode && _isQuranUsageExceeded),
                                                                      autofocus: false,
                                                                      textAlignVertical: TextAlignVertical.center,
                                                                      textDirection: _containsArabic(_searchController.text) ? TextDirection.rtl : TextDirection.ltr,
                                                                      textAlign: _containsArabic(_searchController.text) ? TextAlign.right : TextAlign.left,
                                                                      keyboardType: TextInputType.text,
                                                                      keyboardAppearance: widget.isDarkMode ? Brightness.dark : Brightness.light,
                                                                      cursorColor: _isEmsileMode ? const Color(0xFF384D75) : _isQuranMode ? const Color(0xFF8BC34A) : const Color(0xFF007AFF),
                                                                      showCursor: true,
                                                                      enableInteractiveSelection: true,
                                                                      enableIMEPersonalizedLearning: true,
                                                                      autofillHints: null,
                                                                      style: TextStyle(
                                                                        fontSize: _containsArabic(_searchController.text) ? 19 : 15,
                                                                        height: 1.15,
                                                                        color: widget.isDarkMode ? Colors.white : const Color(0xFF1C1C1E),
                                                                        fontWeight: FontWeight.w500,
                                                                        decoration: TextDecoration.none,
                                                                      ),
                                                                      decoration: InputDecoration(
                                                                        hintText: 'Kelime ara',
                                                                        hintStyle: TextStyle(
                                                                          color: widget.isDarkMode ? const Color(0xFF8E8E93).withOpacity(0.8) : const Color(0xFF8E8E93),
                                                                          fontSize: 13,
                                                                          fontWeight: FontWeight.w400,
                                                                        ),
                                                                        border: InputBorder.none,
                                                                        enabledBorder: InputBorder.none,
                                                                        focusedBorder: InputBorder.none,
                                                                        isDense: true,
                                                                        contentPadding: EdgeInsets.zero,
                                                                        fillColor: Colors.transparent,
                                                                        filled: false,
                                                                      ),
                                                                      textInputAction: TextInputAction.search,
                                                                      onSubmitted: (_) => _searchWithAI(),
                                                                      readOnly: _showArabicKeyboard,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets.only(right: 4),
                                                                child: Material(
                                                                  color: Colors.transparent,
                                                                  child: InkWell(
                                                                    onTap: () {
                                                                      if (_isQuranMode && _isQuranUsageExceeded) return;
                                                                      if (_isListening) { _stopListening(); } else { _startListening(); }
                                                                    },
                                                                    borderRadius: BorderRadius.circular(20),
                                                                    child: Container(
                                                                      width: 36,
                                                                      height: 36,
                                                                      decoration: BoxDecoration(
                                                                        color: _isListening ? Colors.red : (widget.isDarkMode ? const Color(0xFF3A3A3C).withOpacity(0.5) : const Color(0xFFE5E5EA).withOpacity(0.5)),
                                                                        shape: BoxShape.circle,
                                                                      ),
                                                                      child: Icon(
                                                                        _isListening ? Icons.mic : Icons.mic_none_outlined,
                                                                        color: _isListening ? Colors.white : (widget.isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF636366)),
                                                                        size: 22,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsets.only(right: 4),
                                                                child: Material(
                                                                  color: Colors.transparent,
                                                                  child: InkWell(
                                                                    onTap: () {
                                                                      if (_isQuranMode && _isQuranUsageExceeded) return;
                                                                      setState(() {
                                                                        _showArabicKeyboard = !_showArabicKeyboard;
                                                                        if (_showArabicKeyboard) {
                                                                          _searchFocusNode.unfocus();
                                                                          TurkceAnalyticsService.arapcaKlavyeKullanildi();
                                                                        }
                                                                      });
                                                                      widget.onArabicKeyboardStateChanged?.call(_showArabicKeyboard);
                                                                    },
                                                                    borderRadius: BorderRadius.circular(20),
                                                                    child: Container(
                                                                      width: 36,
                                                                      height: 36,
                                                                      decoration: BoxDecoration(
                                                                        color: _showArabicKeyboard
                                                                            ? (_isQuranMode ? const Color(0xFF4A5729) : const Color(0xFF007AFF))
                                                                            : (widget.isDarkMode ? const Color(0xFF3A3A3C).withOpacity(0.5) : const Color(0xFFE5E5EA).withOpacity(0.5)),
                                                                        shape: BoxShape.circle,
                                                                      ),
                                                                      child: Icon(
                                                                        Icons.keyboard_alt_outlined,
                                                                        color: _showArabicKeyboard ? Colors.white : (widget.isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF636366)),
                                                                        size: 22,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              if (_searchController.text.isNotEmpty)
                                                                Padding(
                                                                  padding: const EdgeInsets.only(right: 6),
                                                                  child: GestureDetector(
                                                                    onTap: () {
                                                                      _searchController.clear();
                                                                      _lastSearchText = '';
                                                                      setState(() {
                                                                        _searchResults = [];
                                                                        _quranSearchResults = [];
                                                                        _selectedWord = null;
                                                                        _selectedQuranWord = null;
                                                                        _isSearching = false;
                                                                        _showAIButton = false;
                                                                        _showNotFound = false;
                                                                      });
                                                                    },
                                                                    child: Container(
                                                                      width: 28,
                                                                      height: 28,
                                                                      decoration: BoxDecoration(
                                                                        color: widget.isDarkMode ? Colors.white.withOpacity(0.08) : const Color(0xFF8E8E93).withOpacity(0.08),
                                                                        shape: BoxShape.circle,
                                                                      ),
                                                                      child: Icon(
                                                                        Icons.clear,
                                                                        color: widget.isDarkMode ? const Color(0xFF8E8E93).withOpacity(0.8) : const Color(0xFF8E8E93),
                                                                        size: 14,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                ],
                                              ),
                                      ),
                                      Container(
                                        height: 40,
                                        padding: const EdgeInsets.all(3),
                                        margin: const EdgeInsets.symmetric(horizontal: 0),
                                        decoration: BoxDecoration(
                                          color: widget.isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFEBEBEB),
                                          borderRadius: BorderRadius.circular(12),
                                          border: widget.isDarkMode ? Border.all(color: const Color(0xFF38383A), width: 1) : null,
                                        ),
                                        child: LayoutBuilder(
                                          builder: (context, constraints) {
                                            final double tabWidth = constraints.maxWidth / 4;
                                            final int selectedIdx = _isEmsileMode ? 0 : (_isQuranMode ? 2 : (_isCeviriMode ? 3 : 1));
                                            Color activeColor;
                                            if (_isEmsileMode) {
                                              activeColor = widget.isDarkMode ? const Color(0xFF1E3562) : const Color(0xFF384D75);
                                            } else if (_isQuranMode) {
                                              activeColor = widget.isDarkMode ? const Color(0xFF2C3E18) : const Color(0xFF4A5729);
                                            } else if (_isCeviriMode) {
                                              activeColor = widget.isDarkMode ? const Color(0xFF1a73e8) : const Color(0xFF1a73e8);
                                            } else {
                                              activeColor = widget.isDarkMode ? const Color(0xFF007AFF) : const Color(0xFF007AFF);
                                            }
                                            return Stack(
                                              children: [
                                                AnimatedPositioned(
                                                  duration: const Duration(milliseconds: 250),
                                                  curve: Curves.easeOutCubic,
                                                  left: selectedIdx * tabWidth,
                                                  top: 0,
                                                  bottom: 0,
                                                  width: tabWidth,
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: activeColor,
                                                      borderRadius: BorderRadius.circular(9),
                                                    ),
                                                  ),
                                                ),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onTap: () { dictionaryModeNotifier.value = DictionaryMode.emsile; },
                                                        child: Center(
                                                          child: AnimatedDefaultTextStyle(
                                                            duration: const Duration(milliseconds: 200),
                                                            style: TextStyle(fontSize: 12, fontFamily: GoogleFonts.inter().fontFamily, fontWeight: _isEmsileMode ? FontWeight.w600 : FontWeight.w500, color: _isEmsileMode ? Colors.white : const Color(0xFF8E8E93)),
                                                            child: const Text('Emsile'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onTap: () { dictionaryModeNotifier.value = DictionaryMode.sozluk; },
                                                        child: Center(
                                                          child: AnimatedDefaultTextStyle(
                                                            duration: const Duration(milliseconds: 200),
                                                            style: TextStyle(fontSize: 12, fontFamily: GoogleFonts.inter().fontFamily, fontWeight: (!_isQuranMode && !_isEmsileMode && !_isCeviriMode) ? FontWeight.w600 : FontWeight.w500, color: (!_isQuranMode && !_isEmsileMode && !_isCeviriMode) ? Colors.white : const Color(0xFF8E8E93)),
                                                            child: const Text('Sozluk'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onTap: () { dictionaryModeNotifier.value = DictionaryMode.kuranSozluk; },
                                                        child: Center(
                                                          child: AnimatedDefaultTextStyle(
                                                            duration: const Duration(milliseconds: 200),
                                                            style: TextStyle(fontSize: 12, fontFamily: GoogleFonts.inter().fontFamily, fontWeight: _isQuranMode ? FontWeight.w600 : FontWeight.w500, color: _isQuranMode ? Colors.white : const Color(0xFF8E8E93)),
                                                            child: const Text('Kuran'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: GestureDetector(
                                                        behavior: HitTestBehavior.opaque,
                                                        onTap: () {
                                                          if (dictionaryModeNotifier.value != DictionaryMode.ceviri) {
                                                            _searchController.clear();
                                                            _searchFocusNode.unfocus();
                                                            _lastSearchText = '';
                                                            setState(() {
                                                              dictionaryModeNotifier.value = DictionaryMode.ceviri;
                                                              _isSearching = false;
                                                              _searchResults = [];
                                                            });
                                                          }
                                                        },
                                                        child: Center(
                                                          child: AnimatedDefaultTextStyle(
                                                            duration: const Duration(milliseconds: 200),
                                                            style: TextStyle(fontSize: 12, fontFamily: GoogleFonts.inter().fontFamily, fontWeight: _isCeviriMode ? FontWeight.w600 : FontWeight.w500, color: _isCeviriMode ? Colors.white : const Color(0xFF8E8E93)),
                                                            child: const Text('Ceviri'),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
"""

middle_lines = [line + '\n' for line in sliver_app_bar.split('\n')]

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(header + middle_lines + footer)

print('SUCCESS: File rewritten.')
print(f'New total lines: {len(header) + len(middle_lines) + len(footer)}')
