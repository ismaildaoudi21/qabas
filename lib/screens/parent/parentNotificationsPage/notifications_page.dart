import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:qabas/utils/app_images.dart';

class ParentNotificationsPage extends StatefulWidget {
  const ParentNotificationsPage({super.key});

  @override
  State<ParentNotificationsPage> createState() =>
      _ParentNotificationsPageState();
}

class _ParentNotificationsPageState extends State<ParentNotificationsPage> {
  var screenWidth, screenHeight;
  List dataList = [
    {'date': '5 فبراير 2024', 'isLate': true, 'days': 5},
    {'date': '28 يناير 2024', 'isLate': true, 'days': 2},
    {'date': '2 فبراير 2024', 'isLate': false, 'days': 2},
  ];

  @override
  Widget build(BuildContext context) {
    // Getting screen width and height
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xfffaf7ee),
        body: SafeArea(
          child: Column(
            children: [
              //======================== AppBar Section ========================
              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: _buildAppBar(),
              ),
              //======================== Title Section =========================
              Padding(
                padding: EdgeInsetsDirectional.only(
                    top: screenHeight * 0.02,
                    bottom: screenHeight * 0.02,
                    start: screenWidth * 0.05),
                child: _TitleSection(),
              ),
              //==================== Notifications Section =====================
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: _NotificationsListView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _NotificationsListView() {
    return ListView.builder(
        itemCount: dataList.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _NotificationCard(
              date: dataList[index]['date'],
              isLate: dataList[index]['isLate'],
              days: dataList[index]['days'],
              onClose: () => setState(
                () => dataList.removeAt(index),
              ),
            ),
          );
        });
  }

  Container _NotificationCard(
      {required String date,
      required bool isLate,
      required int days,
      required void Function() onClose}) {
    return Container(
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              offset: const Offset(0, 0), //(x, y)
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
          color: !isLate
              ? AppColors.green2
              : isLate && days > 2
                  ? Colors.red
                  : AppColors.orange2,
          borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            _notificationDateAndClose(date, onClose),
            const SizedBox(height: 8),
            _notificationMessage(isLate, days),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Row _notificationDateAndClose(String date, void Function() onClose) {
    return Row(
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text(
          date,
          style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontFamily: 'Tajwal',
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        InkWell(
            onTap: onClose,
            child:
                const Icon(Icons.close_rounded, color: Colors.white, size: 26)),
      ],
    );
  }

  Row _notificationMessage(bool isLate, int days) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            !isLate
                ? '${_arabicDaysFormatter(days, isLate)} على موعد سداد الرسوم، لا تتأخر في سدادها'
                : isLate && days > 2
                    ? '${_arabicDaysFormatter(days, isLate)} على موعد سداد الرسوم، سددها الآن'
                    : '${_arabicDaysFormatter(days, isLate)} على موعد سداد الرسوم، سارع بسدادها',
            style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontFamily: 'Tajwal',
                fontWeight: FontWeight.bold),
          ),
        ),
        const Icon(FontAwesomeIcons.sackDollar, color: Colors.white)
      ],
    );
  }

  String _arabicDaysFormatter(int number, bool isLate) {
    switch (isLate) {
      case true:
        if (number == 1) {
          return "مر يوم";
        } else if (number == 2) {
          return "مر يومان";
        } else if (number > 3 && number < 11) {
          return "مرت $number أيام";
        } else if ((number > 10 && number < 100) || number % 100 != 0) {
          return "مر $number يومًا";
        } else {
          return "مر $number يوم";
        }
      case false:
        if (number == 1) {
          return "بقي يوم";
        } else if (number == 2) {
          return "بقي يومان";
        } else if (number > 3 && number < 11) {
          return "بقيت $number أيام";
        } else if ((number > 10 && number < 100) || number % 100 != 0) {
          return "بقي $number يومًا";
        } else {
          return "بقي $number يوم";
        }
    }
  }

  Row _TitleSection() {
    return Row(
      children: [
        const SizedBox(width: 15),
        const Spacer(),
        const Text(
          'الإشعارات',
          style: TextStyle(
              fontSize: 26, color: AppColors.green1, fontFamily: 'Tajwal'),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => setState(() => dataList.clear()),
          icon: Image.asset(
            trashIcon,
            width: 20,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 8)
      ],
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        const SizedBox(
          width: 10,
          child: Icon(
            FontAwesomeIcons.ellipsisVertical,
            color: AppColors.green1,
          ),
        ),
        const Spacer(),
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: ClipOval(
            child: Image.asset(
              appLogo2,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const Spacer(),
        const SizedBox(width: 10)
      ],
    );
  }
}
