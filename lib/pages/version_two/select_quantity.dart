import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:patrol_system/controls/text.dart';
import 'package:patrol_system/utils/color_const.dart';
import 'package:patrol_system/utils/constants.dart';
import 'package:patrol_system/utils/utils.dart';

class SelectQuantity extends StatefulWidget {
  const SelectQuantity({super.key});

  @override
  State<SelectQuantity> createState() => _SelectQuantityState();
}

class _SelectQuantityState extends State<SelectQuantity> {
  List<int> list = [];

  @override
  void initState() {
    setState(() {
      list.add(1);
      list.add(2);
      list.add(3);
      list.add(4);
      list.add(5);
      list.add(6);
      list.add(7);
      list.add(8);
      list.add(9);
      list.add(10);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.mainBackground,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 190),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            Get.back(result: list[index]);
                          },
                          child: Card(
                            color: AppTheme.white,
                            margin: const EdgeInsets.only(
                                left: 20, right: 20, bottom: 10),
                            surfaceTintColor: AppTheme.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15.0),
                                child: CText(
                                  textAlign: TextAlign.start,
                                  padding: const EdgeInsets.only(
                                      right: 10, top: 20, bottom: 5),
                                  text: list[index].toString(),
                                  textColor: AppTheme.colorPrimary,
                                  fontFamily: AppTheme.urbanist,
                                  fontSize: AppTheme.large,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                        );
                      }),
                  Utils().sizeBoxHeight()
                ],
              ),
            ),
            Container(
                height: 182,
                color: AppTheme.colorPrimary,
                width: double.infinity,
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Get.back();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(
                            left: 10, top: 50, right: 10, bottom: 20),
                        child: Card(
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12))),
                          elevation: 0,
                          surfaceTintColor: AppTheme.white.withValues(alpha: 0),
                          color: AppTheme.white.withValues(alpha: 0),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Image.asset(
                              "${ASSET_PATH}back.png",
                              height: 15,
                              width: 15,
                              color: AppTheme.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: CText(
                        textAlign: TextAlign.center,
                        padding: const EdgeInsets.only(
                            left: 0, right: 0, top: 35, bottom: 0),
                        text: "Select Quantity",
                        textColor: AppTheme.textPrimary,
                        fontFamily: AppTheme.urbanist,
                        fontSize: AppTheme.big,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )),
          ],
        ));
  }
}
