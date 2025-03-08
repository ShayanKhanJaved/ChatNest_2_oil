import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    
    // Add listener to search controller for real-time searching
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // This method is called whenever the text changes in the search field
  void _onSearchChanged() {
    if (_searchController.text.length >= 1) {
      _performSearch(_searchController.text);
    } else {
      setState(() {
        _searchResults = [];
      });
    }
  }
  
  // Perform the search query to Firestore
  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });
    
    try {
      // Create a lowercase version of the query for case-insensitive searching
      final String lowercaseQuery = query.toLowerCase();
      
      // Get all users (we'll filter and sort client-side for better match ranking)
      final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(50) // Reasonable limit to avoid loading too much data
          .get();
      
      // Convert to list for filtering and sorting
      final List<Map<String, dynamic>> users = userSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final username = (data['username'] ?? '').toString();
        
        // Calculate relevance score (exact matches score higher)
        double relevanceScore = 0;
        if (username.toLowerCase() == lowercaseQuery) {
          relevanceScore = 10; // Exact match
        } else if (username.toLowerCase().startsWith(lowercaseQuery)) {
          relevanceScore = 8; // Starts with query
        } else if (username.toLowerCase().contains(lowercaseQuery)) {
          relevanceScore = 5; // Contains query
        } else {
          return null; // Not a match at all
        }
        
        return {
          'id': doc.id,
          'username': username,
          'description': data['description'] ?? 'No description available',
          'followerCount': data['followerCount'] ?? 0,
          'projectCount': data['projectCount'] ?? 0,
          'relevanceScore': relevanceScore,
          'type': 'user',
        };
      }).whereType<Map<String, dynamic>>().toList();
      
      // Sort by relevance score (highest first)
      users.sort((a, b) => (b['relevanceScore'] as double).compareTo(a['relevanceScore'] as double));
      
      setState(() {
        _searchResults = users;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: OilWaterBackgroundPainter(
                  animation: _animationController,
                ),
                child: Container(),
              );
            },
          ),
          
          // Main content
          Column(
            children: [
              // Blurred App bar
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    color: Colors.black.withOpacity(0.4),
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Text(
                          'SEARCH',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Search bar with glassmorphism
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                          prefixIcon: const Icon(Icons.search, color: Colors.white),
                          suffixIcon: _searchController.text.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Search results or loading indicator
              Expanded(
                child: _isSearching
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? Center(
                            child: Text(
                              _searchController.text.isEmpty
                                  ? 'Start typing to search users'
                                  : 'No users found',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 18,
                              ),
                            ),
                          )
                        : _buildSearchResults(),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Build the list of search results
  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return _buildUserProfileCard(result);
      },
    );
  }
  
  // Build user profile card (Instagram-like)
  Widget _buildUserProfileCard(Map<String, dynamic> user) {
    return GestureDetector(
      onTap: () {
        // Navigate to profile page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(userId: user['id']),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Picture (Circle avatar with icon)
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Username
                          Row(
                            children: [
                              Text(
                                user['username'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              
                              // Stats pills
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${user['followerCount']} followers",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${user['projectCount']} projects",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          
                          // Description
                          Text(
                            _truncateDescription(user['description']),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // View profile chevron
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper method to truncate description
  String _truncateDescription(String description) {
    if (description.length <= 100) {
      return description;
    }
    return description.substring(0, 100) + '...';
  }
}

// Custom painter for the oil-water-like animation
class OilWaterBackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  
  OilWaterBackgroundPainter({required this.animation}) : super(repaint: animation);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Black background
    paint.color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Draw the "oil" blobs
    for (int i = 0; i < 10; i++) {
      double x = size.width * (0.1 + 0.8 * math.sin(i * 0.7 + animation.value * math.pi * 2));
      double y = size.height * (0.1 + 0.8 * math.cos(i * 0.5 + animation.value * math.pi * 2));
      double radius = size.width * (0.05 + 0.03 * math.sin(i + animation.value * math.pi * 2));
      
      // Create gradient for oil-like effect
      final Gradient gradient = RadialGradient(
        center: Alignment.center,
        radius: 0.5,
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.2, 0.7, 1.0],
      );
      
      paint.shader = gradient.createShader(
        Rect.fromCircle(center: Offset(x, y), radius: radius)
      );
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(OilWaterBackgroundPainter oldDelegate) => true;
}
