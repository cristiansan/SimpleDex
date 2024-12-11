// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleDEX {
    // Declaración de los tokens ERC-20 que se usarán en el pool de liquidez
    IERC20 public tokenA; // Token A
    IERC20 public tokenB; // Token B

    // Variables para almacenar las reservas de cada token en el pool
    uint256 public reserveA; // Reservas de Token A
    uint256 public reserveB; // Reservas de Token B

    // Dirección del propietario del contrato (generalmente quien gestiona la liquidez inicial)
    address public owner;

    // Eventos para registrar acciones importantes
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    event Swap(address indexed trader, address fromToken, address toToken, uint256 amountIn, uint256 amountOut);

    // Modificador para restringir ciertas funciones al propietario del contrato
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // Constructor: se inicializa el contrato con las direcciones de los tokens que se usarán en el pool
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA); // Token A
        tokenB = IERC20(_tokenB); // Token B
        owner = msg.sender; // El creador del contrato será el propietario
    }

    // Función para añadir liquidez al pool (solo puede ser llamada por el propietario)
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0"); // Validación

        // Transferir tokens desde el propietario hacia el contrato
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        // Actualizar las reservas
        reserveA += amountA;
        reserveB += amountB;

        // Emitir un evento para registrar la acción
        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    // Función para intercambiar Token A por Token B
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be greater than 0"); // Validación

        // Calcular la cantidad de Token B que recibirá el usuario
        // Fórmula: dy = (y * dx) / (x + dx)
        uint256 amountBOut = (reserveB * amountAIn) / (reserveA + amountAIn);
        require(amountBOut > 0 && amountBOut < reserveB, "Insufficient liquidity");

        // Transferir el Token A del usuario al contrato
        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        // Transferir el Token B del contrato al usuario
        tokenB.transfer(msg.sender, amountBOut);

        // Actualizar las reservas
        reserveA += amountAIn;
        reserveB -= amountBOut;

        // Emitir un evento para registrar la operación
        emit Swap(msg.sender, address(tokenA), address(tokenB), amountAIn, amountBOut);
    }

    // Función para intercambiar Token B por Token A
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be greater than 0"); // Validación

        // Calcular la cantidad de Token A que recibirá el usuario
        // Fórmula: dy = (y * dx) / (x + dx)
        uint256 amountAOut = (reserveA * amountBIn) / (reserveB + amountBIn);
        require(amountAOut > 0 && amountAOut < reserveA, "Insufficient liquidity");

        // Transferir el Token B del usuario al contrato
        tokenB.transferFrom(msg.sender, address(this), amountBIn);
        // Transferir el Token A del contrato al usuario
        tokenA.transfer(msg.sender, amountAOut);

        // Actualizar las reservas
        reserveB += amountBIn;
        reserveA -= amountAOut;

        // Emitir un evento para registrar la operación
        emit Swap(msg.sender, address(tokenB), address(tokenA), amountBIn, amountAOut);
    }

    // Función para que el propietario retire liquidez del pool
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA <= reserveA && amountB <= reserveB, "Insufficient reserves");

        // Transferir los tokens desde el contrato al propietario
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        // Actualizar las reservas
        reserveA -= amountA;
        reserveB -= amountB;

        // Emitir un evento para registrar la acción
        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    // Función para consultar el precio de un token en función del otro
    function getPrice(address _token) external view returns (uint256) {
        if (_token == address(tokenA)) {
            return (reserveB * 1e18) / reserveA; // Precio de 1 Token A en términos de Token B
        } else if (_token == address(tokenB)) {
            return (reserveA * 1e18) / reserveB; // Precio de 1 Token B en términos de Token A
        } else {
            revert("Invalid token address");
        }
    }
}
