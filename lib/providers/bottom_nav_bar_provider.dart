import 'package:Artleap.ai/presentation/views/home_section/home_screen/home_screen.dart';
import 'package:Artleap.ai/presentation/views/home_section/new_prompt_section/new_prompt_screen.dart';
import 'package:Artleap.ai/presentation/views/home_section/new_user_profile/user_profile_screen.dart';
import 'package:Artleap.ai/presentation/views/home_section/reels_section/reels_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation/views/home_section/new_comunity_screen/community_screen.dart';

final bottomNavBarProvider = ChangeNotifierProvider<BottomNavBarProvider>(
    (ref) => BottomNavBarProvider());

class BottomNavBarProvider extends ChangeNotifier {
  List<Widget> widgets = [
    CommunityScreen(),
    HomeScreen(),
    PromptScreen(),
    ReelsScreen(),
    UserProfileScreen(),
  ];

  int _pageIndex = 2;
  int get pageIndex => _pageIndex;

  setPageIndex(int index) {
    _pageIndex = index;
    notifyListeners();
  }
}
