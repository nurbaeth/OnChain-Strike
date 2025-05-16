// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract OnChainStrike {
    enum Team { None, Terrorist, CounterTerrorist }
    enum Action { None, Move, Shoot, Plant, Defuse, Pass }
    enum RoundState { Waiting, Active, Finished }

    struct Player {
        address addr;
        Team team;
        uint health;
        bool alive;
    }

    struct Round {
        uint id;
        RoundState state;
        uint currentTurn;
        mapping(address => bool) hasActed;
    }

    mapping(address => Player) public players;
    address[] public playerList;
    Round public round;

    event Joined(address indexed player, Team team);
    event ActionTaken(address indexed player, Action action);
    event RoundStarted(uint indexed roundId);
    event RoundEnded(uint indexed roundId);

    modifier onlyPlayer() {
        require(players[msg.sender].team != Team.None, "Not a registered player");
        _;
    }

    modifier roundIsActive() {
        require(round.state == RoundState.Active, "Round not active");
        _;
    }

    function joinGame(Team team) external {
        require(team == Team.Terrorist || team == Team.CounterTerrorist, "Invalid team");
        require(players[msg.sender].team == Team.None, "Already joined");

        players[msg.sender] = Player(msg.sender, team, 100, true);
        playerList.push(msg.sender);
        emit Joined(msg.sender, team);
    }

    function startRound() external {
        require(round.state != RoundState.Active, "Round already active");
        round = Round({id: round.id + 1, state: RoundState.Active, currentTurn: 0});
        emit RoundStarted(round.id);
    }

    function takeAction(Action action) external onlyPlayer roundIsActive {
        require(!round.hasActed[msg.sender], "Already acted this turn");
        require(players[msg.sender].alive, "You are dead");

        // Simulate action effects (very simplified)
        if (action == Action.Shoot) {
            address target = findTarget(msg.sender);
            if (target != address(0)) {
                players[target].health -= 50;
                if (players[target].health <= 0) {
                    players[target].alive = false;
                }
            }
        }
        // More logic can be added for Move, Plant, Defuse

        round.hasActed[msg.sender] = true;
        emit ActionTaken(msg.sender, action);

        if (checkTurnOver()) {
            endRound();
        }
    }

    function findTarget(address shooter) internal view returns (address) {
        Team shooterTeam = players[shooter].team;
        for (uint i = 0; i < playerList.length; i++) {
            address p = playerList[i];
            if (players[p].team != shooterTeam && players[p].alive) {
                return p;
            }
        }
        return address(0);
    }

    function checkTurnOver() internal view returns (bool) {
        for (uint i = 0; i < playerList.length; i++) {
            if (!round.hasActed[playerList[i]] && players[playerList[i]].alive) {
                return false;
            }
        }
        return true;
    }

    function endRound() internal {
        round.state = RoundState.Finished;
        emit RoundEnded(round.id);
    }

    function getPlayerInfo(address player) external view returns (Team, uint, bool) {
        Player memory p = players[player];
        return (p.team, p.health, p.alive);
    }
}
