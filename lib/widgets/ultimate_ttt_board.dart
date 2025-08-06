import 'package:flutter/material.dart';

class UltimateTTTBoard extends StatelessWidget {
  final List<List<List<String>>> board;
  final List<List<String>> bigBoardStatus;
  final int? activeBigRow;
  final int? activeBigCol;
  final void Function(int bigRow, int bigCol, int smallRow, int smallCol)
  onMove;

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
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: List.generate(3, (bigRow) {
          return Expanded(
            child: Row(
              children: List.generate(3, (bigCol) {
                final isActive =
                    activeBigRow == null ||
                    (activeBigRow == bigRow && activeBigCol == bigCol);
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isActive ? Colors.yellow : Colors.white38,
                        width: 2,
                      ),
                      color: Colors.transparent,
                    ),
                    child: _buildMiniBoard(context, bigRow, bigCol, isActive),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMiniBoard(
    BuildContext context,
    int bigRow,
    int bigCol,
    bool isActive,
  ) {
    String winStatus = bigBoardStatus[bigRow][bigCol];
    if (winStatus != '') {
      return Center(
        child: Text(
          winStatus,
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: Colors.black,
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
              return Expanded(
                child: GestureDetector(
                  onTap: isActive && cellValue == ''
                      ? () => onMove(bigRow, bigCol, smallRow, smallCol)
                      : null,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24, width: 1),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: Text(
                        cellValue,
                        style: TextStyle(
                          fontSize: 28,
                          color: cellValue == "X" ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
