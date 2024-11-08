import 'dart:io';
import 'dart:math';

//캐릭터 기본 클래스 (이름, 체력, 공격력, 방어력)
class Character {
  String name;
  int hp;
  int attack;
  int def;
  bool isDefending = false;

  Character(this.name, this.hp, this.attack, this.def);

//캐릭터 정보 불러오기
  String toFileString() {
    return '$hp,$attack,$def';
  }

  static Character fromFileString(String data, String newName) {
    List<String> parts = data.split(',');
    return Character(
      newName,
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  bool isAlive() => hp > 0; //체력 관리

//몬스터 타격
  void attackMonster(Monster monster) {
    print('\n${name}의 턴');
    int damage = attack;
    monster.takeDamage(damage);
  }

//방어
  void defend() {
    print('\n${name}의 턴');
    print('${name}이(가) 방어 자세를 취했습니다!');
    isDefending = true;
  }

//피격
  void takeDamage(int damage) {
    int actualDamage = isDefending ? 0 : max(1, damage - def);
    isDefending = false;
    hp = max(0, hp - actualDamage);
    print('${name}이(가) ${actualDamage}의 데미지를 받았습니다!');
    showStatus();
  }

//전투 후 현재 상태 출력
  void showStatus() {
    print('${name} - 체력: ${hp}, 공격력: ${attack}, 방어력: ${def}');
  }
}

//몬스터 기본 클래스 (이름, 체력, 공격력, 방어력)
class Monster {
  String name;
  int hp;
  int attack;
  int def;

  Monster(this.name, this.hp, this.attack, this.def);

//몬스터 정보 불러오기
  String toFileString() {
    return '$name,$hp,$attack,$def';
  }

  static Monster fromFileString(String data) {
    List<String> parts = data.split(',');
    return Monster(
      parts[0],
      int.parse(parts[1]),
      int.parse(parts[2]),
      int.parse(parts[3]),
    );
  }

  bool isAlive() => hp > 0; //체력 관리

//플레이어 타격
  void attackPlayer(Character player) {
    print('\n${name}의 턴');
    print('${name}이(가) ${player.name}에게 ${attack}의 데미지를 입혔습니다.');
    player.takeDamage(attack);
  }

//피격
  void takeDamage(int damage) {
    int actualDamage = max(1, damage - def);
    hp = max(0, hp - actualDamage);
    print('${name}이(가) ${actualDamage}의 데미지를 받았습니다.');
    showStatus();
  }

//전투 후 현재 상태 출력
  void showStatus() {
    print('${name} - 체력: ${hp}, 공격력: ${attack}, 방어력: ${def}');
  }
}

//기본 게임 클래스 (각 정보 불러오기, 전투 상황 부여하기, 캐릭터 저장하기, 전투 결과 저장하기)
class Game {
  Character? character;
  List<Monster> monsters = [];
  int defeatedMonsters = 0;
  int targetDefeatedMonsters;
  Random random = Random();

  Game(this.targetDefeatedMonsters);

  // 보너스 체력 부여 기능 추가
  void applyBonusHealth() {
    // 30% 확률로 보너스 체력 부여
    if (random.nextDouble() < 0.3) {
      character!.hp += 10;
      print('보너스 체력을 얻었습니다! 현재 체력: ${character!.hp}');
    }
  }

//캐릭터 저장하기
  void saveCharacter() {
    if (character != null) {
      File('character.txt').writeAsStringSync(character!.toFileString());
    }
  }

//캐릭터 불러오기
  bool loadCharacter() {
    try {
      print('캐릭터의 이름을 입력하세요:');
      String name = stdin.readLineSync() ?? 'Hero';

      var file = File('character.txt');
      if (file.existsSync()) {
        String data = file.readAsStringSync().trim();
        character = Character.fromFileString(data, name);
        return true;
      } else {
        character = Character(name, 50, 10, 5);
        saveCharacter();
        return true;
      }
    } catch (e) {
      print('캐릭터 파일 로딩 중 오류: $e');
      return false;
    }
  }

//몬스터 저장하기
  void saveMonsters() {
    var content = monsters.map((m) => m.toFileString()).join('\n');
    File('monsters.txt').writeAsStringSync(content);
  }

//몬스터 불러오기
  void loadMonsters() {
    try {
      var file = File('monsters.txt');
      if (!file.existsSync()) {
        createDefaultMonsters();
        return;
      }

      monsters.clear();
      var lines = file.readAsLinesSync();
      for (var line in lines) {
        if (line.trim().isNotEmpty) {
          monsters.add(Monster.fromFileString(line));
        }
      }

      if (monsters.isEmpty) {
        createDefaultMonsters();
      }
    } catch (e) {
      print('몬스터 파일 로딩 중 오류: $e');
      createDefaultMonsters();
    }
  }

//몬스터 생성하기
  void createDefaultMonsters() {
    monsters = [
      Monster('Slime', 10, 5, 0),
      Monster('Goblin', 20, 8, 0),
      Monster('Oak', 30, 10, 0),
    ];
    saveMonsters();
  }

//전투 결과 저장하기
  void saveResult(bool victory) {
    print('\n결과를 저장하시겠습니까? (y/n):');
    String? input = stdin.readLineSync()?.toLowerCase();
    
    if (input == 'y') {
      try {
        var file = File('result.txt');
        String resultStatus = victory ? '승리' : '패배';
        String resultString = '${character!.name},${character!.hp},$resultStatus\n';
        
        if (file.existsSync()) {
          file.writeAsStringSync(resultString, mode: FileMode.append);
        } else {
          file.writeAsStringSync(resultString);
        }
        
        print('게임 결과가 저장되었습니다!');
      } catch (e) {
        print('결과 저장 중 오류가 발생했습니다: $e');
      }
    } else {
      print('결과를 저장하지 않았습니다.');
    }
  }

//다음 전투 진행여부 확인
  bool askForNextBattle() {
    print('\n다음 몬스터와 싸우시겠습니까? (y/n):');
    String? input = stdin.readLineSync()?.toLowerCase();
    return input == 'y';
  }

//전투 진행하기
  bool battle() {
    Monster monster = getRandomMonster();
    print('\n새로운 몬스터가 나타났습니다!');
    monster.showStatus();

    while (true) {
      print('\n${character!.name}의 턴');
      print('행동을 선택하세요 (1: 공격, 2: 방어): ');

      String? input = stdin.readLineSync();

      switch (input) {
        case '1':
          character!.attackMonster(monster);
          break;
        case '2':
          character!.defend();
          break;
        default:
          print('잘못된 입력입니다. 다시 선택하세요.');
          continue;
      }

      if (!monster.isAlive()) {
        print('\n${monster.name}을(를) 물리쳤습니다!');
        monsters.remove(monster);
        defeatedMonsters++;
        saveCharacter();
        
        if (defeatedMonsters < targetDefeatedMonsters) {
          if (!askForNextBattle()) {
            print('\n게임을 종료합니다.');
            saveResult(true);
            return false;
          }
          return true;
        } else {
          print('\n모든 몬스터를 물리쳤습니다! 게임에서 승리했습니다!');
          saveResult(true);
          return false;
        }
      }

      monster.attackPlayer(character!);

      if (!character!.isAlive()) {
        print('\n게임 오버! ${character!.name}이(가) 쓰러졌습니다!');
        saveResult(false);
        return false;
      }

      saveCharacter();
    }
  }

  Monster getRandomMonster() {
    return monsters[random.nextInt(monsters.length)];
  }

  void startGame() {
    print('\n=== 게임 시작 ===');

    if (!loadCharacter()) {
      print('캐릭터 생성 중 오류가 발생했습니다.');
      return;
    }

    // 캐릭터 로드 후 보너스 체력 적용
    applyBonusHealth();

    loadMonsters();

    print('게임이 시작됩니다!');
    character!.showStatus();

    while (character!.isAlive() && defeatedMonsters < targetDefeatedMonsters) {
      if (!battle()) {
        if (character!.isAlive() && defeatedMonsters < targetDefeatedMonsters) {
          print('게임을 중단했습니다.');
        }
        return;
      }
    }

    if (character!.isAlive() && defeatedMonsters >= targetDefeatedMonsters) {
      print('\n축하합니다! 게임에서 승리했습니다!');
      saveResult(true);
    }
  }
}

void main() {
  Game game = Game(3);
  game.startGame();
}
