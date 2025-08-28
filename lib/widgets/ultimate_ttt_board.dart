import 'package:flutter/material.dart';

class UltimateTTTBoard extends StatelessWidget {
  final List<List<List<String>>> board;
  final List<List<String>> bigBoardStatus;
  final int? activeBigRow;
  final int? activeBigCol;
  final void Function(int bigRow, int bigCol, int smallRow, int smallCol) onMove;

  const UltimateTTTBoard({
    Key? key,
    required this.board,
    required this.onMove,
    required this.activeBigRow,
    required this.activeBigCol,
    required this.bigBoardStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the smaller dimension to ensure the board fits
        final boardSize = constraints.maxWidth < constraints.maxHeight 
            ? constraints.maxWidth 
            : constraints.maxHeight;
        
        return Center(
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Column(
              children: List.generate(3, (bigRow) {
                return Expanded(
                  child: Row(
                    children: List.generate(3, (bigCol) {
                      final isActive = activeBigRow == null ||
                          (activeBigRow == bigRow && activeBigCol == bigCol);
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.all(boardSize * 0.006), // Slightly reduced margin
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isActive ? Colors.yellow : Colors.white38,
                              width: boardSize * 0.004, // Slightly thicker border
                            ),
                            borderRadius: BorderRadius.circular(boardSize * 0.01),
                            color: Colors.transparent,
                          ),
                          child: _buildMiniBoard(context, bigRow, bigCol, isActive, boardSize),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniBoard(
    BuildContext context,
    int bigRow,
    int bigCol,
    bool isActive,
    double boardSize,
  ) {
    String winStatus = bigBoardStatus[bigRow][bigCol];
    
    if (winStatus != '') {
      return Container(
        decoration: BoxDecoration(
          color: winStatus == 'X' 
              ? Colors.red.withOpacity(0.15)
              : winStatus == 'O' 
                  ? Colors.green.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(boardSize * 0.01),
        ),
        child: Center(
          child: Text(
            winStatus == 'D' ? '=' : winStatus, // Show '=' for draw instead of 'D'
            style: TextStyle(
              fontSize: boardSize * 0.12, // Larger font for big board winners
              fontWeight: FontWeight.bold,
              color: winStatus == 'X' 
                  ? Colors.red
                  : winStatus == 'O' 
                      ? Colors.green
                      : Colors.white,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(3, (smallRow) {
        return Expanded(
          child: Row(
            children: List.generate(3, (smallCol) {
              final cellValue = board[bigRow][bigCol][smallRow * 3 + smallCol];
              final isEmpty = cellValue == '';
              final canTap = isActive && isEmpty;
              
              return Expanded(
                child: GestureDetector(
                  onTap: canTap ? () => onMove(bigRow, bigCol, smallRow, smallCol) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.all(boardSize * 0.001), // Very small margin for cells
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white24, 
                        width: boardSize * 0.001,
                      ),
                      borderRadius: BorderRadius.circular(boardSize * 0.003),
                      color: canTap 
                          ? Colors.white.withOpacity(0.05)
                          : Colors.transparent,
                    ),
                    child: Center(
                      child: cellValue.isNotEmpty
                          ? AnimatedScale(
                              scale: 1.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.elasticOut,
                              child: Text(
                                cellValue,
                                style: TextStyle(
                                  fontSize: boardSize * 0.045, // Significantly larger font for X and O
                                  color: cellValue == "X" ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.4),
                                      offset: const Offset(1, 1),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : canTap
                              ? Icon(
                                  Icons.add,
                                  size: boardSize * 0.025, // Larger add icon
                                  color: Colors.white.withOpacity(0.4),
                                )
                              : null,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}