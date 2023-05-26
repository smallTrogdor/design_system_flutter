import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../design_system_flutter.dart';

const _itemHeight = 30.0;
const _highlightedAreaHeight = 34.0;
const _visibleItemCount = 7;
const _scrollAreaHeight = _itemHeight * _visibleItemCount;
const _visibleItemHeights = [
  28.0,
  28.0,
  30.0,
  38.0,
  30.0,
  28.0,
  28.0,
];
const _visibleItemTextColors = [
  SBBColors.silver,
  SBBColors.cement,
  SBBColors.storm,
  SBBColors.storm,
  SBBColors.storm,
  SBBColors.cement,
  SBBColors.silver,
];

enum SBBDateTimePickerMode {
  time,
  date,
  dateAndTime,
}

class SBBPicker extends StatelessWidget {
  SBBPicker({
    Key? key,
    String? label,
    int initialSelectedIndex = 0,
    required ValueChanged<int>? onSelectedItemChanged,
    required IndexedWidgetBuilder itemBuilder,
    bool isLastElement = true,
  }) : this._(
          key: key,
          label: label,
          child: SBBPickerScrollView(
            initialSelectedIndex: initialSelectedIndex,
            onSelectedItemChanged: onSelectedItemChanged,
            itemBuilder: itemBuilder,
          ),
          isLastElement: isLastElement,
        );

  const SBBPicker._({
    super.key,
    this.label,
    required this.child,
    this.isLastElement = true,
  });

  final String? label;
  final Widget child;
  final bool isLastElement;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (label != null)
          Padding(
            padding: EdgeInsets.only(
              top: 5.0,
              bottom: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label!,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: SBBTextStyles.helpersLabel,
                  ),
                ),
              ],
            ),
          ),
        Container(
          height: 224,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: _buildHighlightedArea(),
              ),
              Center(
                child: ShaderMask(
                  shaderCallback: _shaderCallback,
                  child: Container(
                    height: _scrollAreaHeight,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (label != null && !isLastElement)
          SizedBox(
            height: sbbDefaultSpacing * 0.5,
          ),
        if (!isLastElement) Divider(),
      ],
    );
  }

  Widget _buildHighlightedArea() {
    return Container(
      height: _highlightedAreaHeight,
      margin: EdgeInsets.symmetric(
        horizontal: sbbDefaultSpacing * 0.5,
      ),
      decoration: BoxDecoration(
        color: SBBColors.cloud,
        borderRadius: BorderRadius.all(
          Radius.circular(
            sbbDefaultSpacing * 0.5,
          ),
        ),
      ),
    );
  }

  Shader _shaderCallback(bounds) {
    const topFadeOutStartStop = 3.0 / _scrollAreaHeight;
    final topFadeOutEndStop = _visibleItemHeights[0] / _scrollAreaHeight;
    const highlightedAreaStartStop =
        (_scrollAreaHeight - _highlightedAreaHeight) * 0.5 / _scrollAreaHeight;
    const highlightedAreaEndStop = 1.0 - highlightedAreaStartStop;
    final bottomFadeOutStartStop = 1.0 - topFadeOutEndStop;
    const bottomFadeOutEndStop = 1.0 - topFadeOutStartStop;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [
        topFadeOutStartStop,
        topFadeOutEndStop,
        highlightedAreaStartStop,
        highlightedAreaStartStop,
        highlightedAreaEndStop,
        highlightedAreaEndStop,
        bottomFadeOutStartStop,
        bottomFadeOutEndStop,
      ],
      colors: [
        SBBColors.white.withOpacity(0.0),
        SBBColors.white,
        SBBColors.white,
        SBBColors.black,
        SBBColors.black,
        SBBColors.white,
        SBBColors.white,
        SBBColors.white.withOpacity(0.0),
      ],
    ).createShader(
      bounds,
    );
  }
}

class SBBDateTimePicker extends StatefulWidget {
  const SBBDateTimePicker({
    super.key,
    this.label,
    this.mode = SBBDateTimePickerMode.dateAndTime,
    required this.onDateTimeChanged,
    this.initialDateTime,
    this.minimumDate,
    this.maximumDate,
    this.isLastElement = true,
    this.minuteInterval = 1,
  });

  final String? label;
  final SBBDateTimePickerMode mode;
  final ValueChanged<DateTime> onDateTimeChanged;
  final DateTime? initialDateTime;
  final DateTime? minimumDate;
  final DateTime? maximumDate;
  final int minuteInterval;
  final bool isLastElement;

  @override
  State<SBBDateTimePicker> createState() => _SBBDateTimePickerState();
}

class _SBBDateTimePickerState extends State<SBBDateTimePicker> {
  final pickerItemTextColorDisabledLight = SBBColors.storm;
  final pickerItemTextColorDisabledDark = SBBColors.metal;
  final maxDaysInMonth = 31;

  final startDateTime = DateTime.now();
  late DateTime selectedDateTime = widget.initialDateTime ?? startDateTime;
  late int initialHourIndex = selectedDateTime.hour;
  late int initialMinuteIndex =
      (selectedDateTime.minute / widget.minuteInterval).ceil();

  late int initialDayIndex = selectedDateTime.day - 1;
  late int initialMonthIndex = selectedDateTime.month - 1;
  late int initialYearIndex = selectedDateTime.year - startDateTime.year;

  late SBBPickerScrollController dayController = SBBPickerScrollController(
    initialItem: initialDayIndex,
  );
  late SBBPickerScrollController monthController = SBBPickerScrollController(
    initialItem: initialMonthIndex,
  );
  late SBBPickerScrollController yearController = SBBPickerScrollController(
    initialItem: initialYearIndex,
  );

  @override
  void initState() {
    selectedDateTime = selectedDateTime.copyWith(
      minute: _minuteByIndex(initialMinuteIndex),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.minuteInterval > 0 && 60 % widget.minuteInterval == 0,
      'minute interval is not a positive integer factor of 60',
    );

    return SBBPicker._(
      label: widget.label,
      isLastElement: widget.isLastElement,
      child: widget.mode == SBBDateTimePickerMode.time
          ? _timeBody(context)
          : widget.mode == SBBDateTimePickerMode.date
              ? _dateBody(context)
              : _dateAndTimeBody(context),
    );
  }

  Widget _timeBody(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SBBPickerScrollView(
            initialSelectedIndex: initialHourIndex,
            onSelectedItemChanged: (int index) {
              final selectedHour = index % 24;
              _onDateTimeSelected(
                hour: selectedHour,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              return Row(
                children: [
                  const Spacer(),
                  Container(
                    width: 48.0,
                    alignment: Alignment.center,
                    child: Text(
                      (index % 24).toString().padLeft(2, '0'),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  const SizedBox(
                    width: 12.0,
                  ),
                ],
              );
            },
          ),
        ),
        Expanded(
          child: SBBPickerScrollView(
            initialSelectedIndex: initialMinuteIndex,
            onSelectedItemChanged: (int index) {
              final selectedMinute = _minuteByIndex(index);
              _onDateTimeSelected(
                minute: selectedMinute,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              return Row(
                children: [
                  const SizedBox(
                    width: 12.0,
                  ),
                  Container(
                    width: 48.0,
                    alignment: Alignment.center,
                    child: Text(
                      _minuteByIndex(index).toString().padLeft(2, '0'),
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                  const Spacer(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _dateBody(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40.0 + 24.0 + 12.0,
          child: SBBPickerScrollView(
            controller: dayController,
            onSelectedItemChanged: (int index) {
              final numberOfSelectableDays = _numberOfDaysInMonth(
                selectedDateTime.year,
                selectedDateTime.month,
              );
              final selectedDay = index % maxDaysInMonth + 1;
              _onDateTimeSelected(
                day: selectedDay,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              final numberOfSelectableDays = _numberOfDaysInMonth(
                selectedDateTime.year,
                selectedDateTime.month,
              );
              final selectedDayIndex = index % maxDaysInMonth;
              final selectedDayEnabled =
                  selectedDayIndex < numberOfSelectableDays;
              return Opacity(
                opacity: selectedDayEnabled ? 1.0 : 0.1,
                child: Container(
                  margin: EdgeInsets.only(
                    left: 24.0,
                    right: 12.0,
                  ),
                  child: Text(
                    '${selectedDayIndex + 1}.',
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: SBBPickerScrollView(
            controller: monthController,
            onSelectedItemChanged: (int index) {
              final selectedMonth = index % 12 + 1;
              _onDateTimeSelected(
                month: selectedMonth,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              final cupertinoLocalizations = Localizations.of(
                context,
                CupertinoLocalizations,
              );
              return Container(
                padding: EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  cupertinoLocalizations.datePickerMonth(index % 12 + 1),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              );
            },
          ),
        ),
        Container(
          width: 64.0 + 12.0 + 24.0,
          child: SBBPickerScrollView(
            controller: yearController,
            onSelectedItemChanged: (int index) {
              final selectedYear = startDateTime.year + index;
              _onDateTimeSelected(
                year: selectedYear,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              return Container(
                margin: EdgeInsets.only(
                  left: 12.0,
                  right: 24.0,
                ),
                child: Text(
                  (startDateTime.year + index).toString(),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _dateAndTimeBody(BuildContext context) {
    final cupertinoLocalizations = Localizations.of(
      context,
      CupertinoLocalizations,
    );
    return Row(
      children: [
        Expanded(
          child: SBBPickerScrollView(
            onSelectedItemChanged: (int index) {
              final selectedDate = startDateTime.add(
                Duration(days: index),
              );
              _onDateTimeSelected(
                year: selectedDate.year,
                month: selectedDate.month,
                day: selectedDate.day,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              final dateTime = startDateTime.add(
                Duration(days: index),
              );
              final isToday = dateTime.year == startDateTime.year &&
                  dateTime.month == startDateTime.month &&
                  dateTime.day == startDateTime.day;
              return Container(
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 12.0,
                ),
                alignment: Alignment.centerRight,
                child: Text(
                  isToday
                      ? cupertinoLocalizations.todayLabel
                      : cupertinoLocalizations.datePickerMediumDate(
                          dateTime,
                        ),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              );
            },
          ),
        ),
        Container(
          width: 48.0 + 12.0 + 12.0,
          child: SBBPickerScrollView(
            initialSelectedIndex: initialHourIndex,
            onSelectedItemChanged: (int index) {
              final selectedHour = index % 24;
              _onDateTimeSelected(
                hour: selectedHour,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              return Container(
                padding: EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                ),
                alignment: Alignment.center,
                child: Text(
                  (index % 24).toString().padLeft(2, '0'),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              );
            },
          ),
        ),
        Container(
          width: 48.0 + 12.0 + 24.0,
          child: SBBPickerScrollView(
            initialSelectedIndex: initialMinuteIndex,
            onSelectedItemChanged: (int index) {
              final selectedMinute = _minuteByIndex(index);
              _onDateTimeSelected(
                minute: selectedMinute,
              );
            },
            itemBuilder: (BuildContext context, int index) {
              return Container(
                padding: EdgeInsets.only(
                  left: 12.0,
                  right: 24.0,
                ),
                alignment: Alignment.center,
                child: Text(
                  _minuteByIndex(index).toString().padLeft(2, '0'),
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onDateTimeSelected({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
  }) {
    final selectedYear = year ?? selectedDateTime.year;
    final selectedMonth = month ?? selectedDateTime.month;
    var selectedDay = day ?? selectedDateTime.day;
    final selectedHour = hour ?? selectedDateTime.hour;
    final selectedMinute = minute ?? selectedDateTime.minute;
    var notifyCallback = true;

    if (widget.mode == SBBDateTimePickerMode.date) {
      final isDayChanging = day != null;

      if (isDayChanging) {
        final isDayControllerIdle =
            !dayController.position.isScrollingNotifier.value;
        debugPrint('DEBUG: $isDayControllerIdle');
        final currentMonthDays = _numberOfDaysInMonth(
          selectedDateTime.year,
          selectedDateTime.month,
        );
        if (selectedDay > currentMonthDays) {
          if (!isDayControllerIdle) {
            return;
          }
          notifyCallback = false;
          selectedDay = currentMonthDays;
          dayController.animateToItem(
            selectedDay - 1,
            duration: kThemeAnimationDuration,
            curve: Curves.fastOutSlowIn,
          );
        }
      }

      final isMonthOrYearChanging = day == null;
      if (isMonthOrYearChanging) {
        final isDayControllerIdle =
            !dayController.position.isScrollingNotifier.value;
        final isMonthControllerIdle =
            !monthController.position.isScrollingNotifier.value;
        final isYearControllerIdle =
            !yearController.position.isScrollingNotifier.value;
        debugPrint(
            '$selectedDay.$selectedMonth.$selectedYear : ${dayController.position.isScrollingNotifier.value}');
        if (isDayControllerIdle &&
            isMonthControllerIdle &&
            isYearControllerIdle) {
          final prevMonthDays = _numberOfDaysInMonth(
            selectedDateTime.year,
            selectedDateTime.month,
          );
          if (dayController.selectedItem < 0) {
            notifyCallback = false;
            while (dayController.selectedItem < 0) {
              // dayController.jumpToItem(
              //   dayController.selectedItem + prevMonthDays,
              // );
            }
          } else if (dayController.selectedItem > prevMonthDays - 1) {
            notifyCallback = false;
            while (dayController.selectedItem > prevMonthDays - 1) {
              // dayController.jumpToItem(
              //   dayController.selectedItem - prevMonthDays,
              // );
            }
          }

          final monthDays = _numberOfDaysInMonth(
            selectedYear,
            selectedMonth,
          );
          final dayValueOverflow = selectedDay > monthDays;

          if (dayValueOverflow) {
            // TODO add scrollcontroller for motnh and year and check those => check with cupertino
            debugPrint(
                'OVERFLOW $selectedDay.$selectedMonth.$selectedYear : ${dayController.positions.length} ${dayController.position.isScrollingNotifier.value}');

            selectedDay = monthDays;
            notifyCallback = false;
            // TODO prevent jumpToItem while animating
            // dayController.animateToItem(
            //   selectedDay - 1,
            //   duration: kThemeAnimationDuration,
            //   curve: Curves.fastOutSlowIn,
            // );
          }
        }
      }
    }

    _onDateTimeChanged(
      selectedYear,
      selectedMonth,
      selectedDay,
      selectedHour,
      selectedMinute,
      notifyCallback,
    );
  }

  void _onDateTimeChanged(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    bool notifyCallback,
  ) {
    setState(() {
      selectedDateTime = DateTime(
        year,
        month,
        day,
        hour,
        minute,
      );
    });
    if (notifyCallback) {
      widget.onDateTimeChanged(selectedDateTime);
    }
  }

  int _minuteByIndex(int minuteIndex) {
    return minuteIndex * widget.minuteInterval % 60;
  }

  int _numberOfDaysInMonth(int year, int month) {
    return DateTime(
      year,
      month + 1,
      0,
    ).day;
  }
}

class SBBPickerScrollView extends StatefulWidget {
  const SBBPickerScrollView({
    super.key,
    this.initialSelectedIndex = 0,
    required this.onSelectedItemChanged,
    required this.itemBuilder,
    this.controller,
  });

  final int initialSelectedIndex;
  final ValueChanged<int>? onSelectedItemChanged;
  final IndexedWidgetBuilder itemBuilder;
  final SBBPickerScrollController? controller;

  @override
  State<SBBPickerScrollView> createState() => _SBBPickerScrollViewState();
}

class _SBBPickerScrollViewState extends State<SBBPickerScrollView> {
  final _listCenterKey = UniqueKey();
  late ValueNotifier<double> _scrollOffsetValueNotifier;
  late ValueNotifier<int> _selectedItemIndexValueNotifier;
  SBBPickerScrollController? _fallbackController;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _fallbackController = SBBPickerScrollController(
        initialItem: widget.initialSelectedIndex,
      );
    }
    _scrollOffsetValueNotifier = ValueNotifier(
      _controller.initialScrollOffset,
    );
    _selectedItemIndexValueNotifier = ValueNotifier(
      widget.initialSelectedIndex,
    );
    _selectedItemIndexValueNotifier.addListener(() {
      final onSelectedItemChanged = widget.onSelectedItemChanged;
      if (onSelectedItemChanged != null) {
        Future.delayed(Duration.zero, () {
          onSelectedItemChanged(_selectedItemIndexValueNotifier.value);
        });
      }
    });
    _controller.addListener(() {
      _scrollOffsetValueNotifier.value = _controller.offset;
    });
  }

  @override
  void dispose() {
    _scrollOffsetValueNotifier.dispose();
    _selectedItemIndexValueNotifier.dispose();
    _fallbackController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _scrollAreaHeight,
      child: Scrollable(
        controller: _controller,
        physics: _PickerScrollPhysics(),
        viewportBuilder: (
          BuildContext context,
          ViewportOffset offset,
        ) {
          return Viewport(
            offset: offset,
            center: _listCenterKey,
            slivers: [
              // negative list (index < 0)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    // adjust index so it goes negative from -1 instead of positive from 0
                    final adjustedIndex = -1 * index - 1;
                    return _buildListItem(adjustedIndex);
                  },
                ),
              ),
              // positive list (index >= 0)
              SliverList(
                key: _listCenterKey,
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return _buildListItem(index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListItem(int index) {
    return ValueListenableBuilder(
      valueListenable: _scrollOffsetValueNotifier,
      builder: (
        BuildContext context,
        double offset,
        Widget? _,
      ) {
        final itemsOfBothListsVisible =
            offset < 0 && offset > -_scrollAreaHeight;
        if (itemsOfBothListsVisible) {
          // Because of the workaround used in _PickerScrollPhysics, it's
          // necessary to adjust the offset to ensure that item heights are
          // accurately calculated.
          var threshold = 0.0;
          for (var i = 0; i < _visibleItemCount; i++) {
            threshold -= _visibleItemHeights[i];
            if (threshold <= offset) {
              final offsetPercentage = offset / threshold;
              final maxCorrectedOffset = (-1 - i) * _itemHeight;
              offset = offsetPercentage * maxCorrectedOffset;
              break;
            }
          }
        }

        // includes items that are partly visible when scrolling
        final visibleItemIndex =
            ((offset - index * _itemHeight) * -1 / _itemHeight).ceil();

        if (visibleItemIndex < 0 || visibleItemIndex > _visibleItemCount) {
          return const SizedBox(
            height: _itemHeight,
          );
        }

        // check selected item
        final visibleAreaOffset = offset % _itemHeight;
        var selectedVisibleItemIndex =
            visibleAreaOffset > _itemHeight * 0.5 ? 4 : 3;
        final selectedItemIndex =
            index + selectedVisibleItemIndex - visibleItemIndex;
        _selectedItemIndexValueNotifier.value = selectedItemIndex;

        final indexA = visibleItemIndex - 1;
        final indexB = visibleItemIndex;
        final weightA = (offset % _itemHeight) / _itemHeight;
        final weightB = 1 - weightA;
        final heightA = _getItemHeight(indexA);
        final heightB = _getItemHeight(indexB);
        final textColorA = _getItemTextColor(indexA);
        final textColorB = _getItemTextColor(indexB);

        final itemHeight = weightA * heightA + weightB * heightB;
        final textColor = Color.lerp(
          textColorA,
          textColorB,
          weightB,
        );

        return GestureDetector(
          onTap: () {
            _controller.animateToItem(
              index,
              duration: kThemeAnimationDuration,
              curve: Curves.fastOutSlowIn,
            );
          },
          child: Container(
            height: itemHeight,
            width: double.infinity,
            alignment: Alignment.center,
            child: DefaultTextStyle(
              style: SBBTextStyles.mediumLight.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 24.0,
                height: 26.0 / 24.0,
                color: textColor,
              ),
              child: widget.itemBuilder(
                context,
                index,
              ),
            ),
          ),
        );
      },
    );
  }

  double _getItemHeight(int index) {
    if (index < 0 || index > _visibleItemCount - 1) {
      return _itemHeight;
    }
    return _visibleItemHeights[index];
  }

  Color _getItemTextColor(int index) {
    if (index < 0) {
      return _visibleItemTextColors.first;
    }
    if (index > _visibleItemCount - 1) {
      return _visibleItemTextColors.last;
    }
    return _visibleItemTextColors[index];
  }

  SBBPickerScrollController get _controller {
    return widget.controller ?? _fallbackController!;
  }
}

class SBBPickerScrollController extends ScrollController {
  SBBPickerScrollController({
    int initialItem = 0,
  }) : super(
          initialScrollOffset: _getItemScrollOffset(
            initialItem,
          ),
        );

  int get selectedItem {
    // final visibleItemIndex =
    // ((offset - index * _itemHeight) * -1 / _itemHeight).ceil();
    // final visibleAreaOffset = offset % _itemHeight;
    // var selectedVisibleItemIndex =
    // visibleAreaOffset > _itemHeight * 0.5 ? 4 : 3;
    // final selectedItemIndex =
    //     index + selectedVisibleItemIndex - visibleItemIndex;
    return (offset / _itemHeight).round() + 3;
  }

  Future<void> animateToItem(
    int itemIndex, {
    required Duration duration,
    required Curve curve,
  }) async {
    final targetItemScrollOffset = _getItemScrollOffset(itemIndex);
    animateTo(
      targetItemScrollOffset,
      duration: kThemeAnimationDuration,
      curve: Curves.fastOutSlowIn,
    );
  }

  void jumpToItem(int itemIndex) {
    final targetItemScrollOffset = _getItemScrollOffset(itemIndex);
    jumpTo(targetItemScrollOffset);
  }

  static double _getItemScrollOffset(int index) {
    final targetItemScrollOffset = (index - 3) * _itemHeight;
    return _PickerScrollPhysics._calculateTargetScrollPosition(
      targetItemScrollOffset,
    );
  }
}

class _PickerScrollPhysics extends ScrollPhysics {
  const _PickerScrollPhysics({ScrollPhysics? parent}) : super(parent: parent);

  @override
  _PickerScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _PickerScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (velocity == 0.0) {
      final scrollPosition = position.pixels;
      final target = _calculateTargetScrollPosition(scrollPosition);
      if (target != scrollPosition) {
        return ScrollSpringSimulation(
          spring,
          scrollPosition,
          target,
          velocity,
          tolerance: tolerance,
        );
      }
    }

    return parent!.createBallisticSimulation(position, velocity);
  }

  static double _calculateTargetScrollPosition(double scrollPosition) {
    final itemsOfBothListsVisible =
        scrollPosition < 0 && scrollPosition > -_scrollAreaHeight;
    if (itemsOfBothListsVisible) {
      // Because the heights of list items vary depending on their positions,
      // it's necessary to handle the area where items from both the positive
      // and negative lists are visible differently. This is because the
      // calculation for the target scroll position isn't accurate when both
      // lists are scrolling simultaneously. Therefore, the calculation for the
      // target scroll position must be adjusted.
      for (var i = 0; i < _visibleItemCount; i++) {
        var threshold = 0.0;
        for (var j = 0; j < i; j++) {
          threshold -= _visibleItemHeights[j];
        }
        threshold -= _visibleItemHeights[i] * 0.5;
        if (scrollPosition > threshold) {
          return threshold + _visibleItemHeights[i] * 0.5;
        }
      }
    }

    return (scrollPosition / _itemHeight).round() * _itemHeight;
  }

  @override
  bool get allowImplicitScrolling => false;
}
