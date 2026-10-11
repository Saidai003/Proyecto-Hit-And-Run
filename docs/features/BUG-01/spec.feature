Feature: El perseguidor queda bloqueado durante la animación de romper el pale

  Como jugador que persigue, quiero quedar inmovilizado mientras rompo un pale
  caído para que la animación no se corte y el golpe siempre se complete.

  Background:
    Given una ronda 1v1 activa en "Prototipo: Golpear y huir" (placeId 118890619753629)
    And el jugador A tiene el rol PERSEGUIDO
    And el jugador B tiene el rol PERSEGUIDOR

  Scenario: Romper sin moverse deja el pale roto
    Given el pale P está en estado "Caido"
    When el perseguidor B se para junto a P y pulsa Espacio
    Then el servidor imprime "[SERVIDOR]: Procesando interacción" y ejecuta romperPale
    And B no se mueve durante los 2.0 s de la animación
    And P termina en estado "Roto" y su InvisibleWall.CanCollide == false

  Scenario: Moverse a media animación no interrumpe el golpe
    Given el pale P está en estado "Caido"
    When el perseguidor B pulsa Espacio y mantiene WASD durante toda la animación
    Then la posición de B no cambia (Humanoid.WalkSpeed == 0 de forma sostenida)
    And la animación de romper sigue corriendo los 2.0 s completos
    And P termina en estado "Roto"

  Scenario: El bloqueo viaja por el evento, no solo por el atributo
    Given el perseguidor B ha iniciado romper un pale
    Then el servidor envía BLOQUEAR_MOVIMIENTO al cliente de B
    And el flag local movimientoBloqueado de B es true
    And el Heartbeat del cliente deja de escribir WalkSpeed

  Scenario: El movimiento vuelve tras la animación
    When termina la animación de romper (2.0 s)
    Then el servidor envía DESBLOQUEAR_MOVIMIENTO al cliente de B
    And movimientoBloqueado de B es false
    And el Heartbeat reanuda y WalkSpeed vuelve a velocidadBase

  Scenario: El stun del perseguidor también lo bloquea
    Given el pale P está en estado "Caido"
    When el perseguidido A lo deja caer sobre B a menos de STUN_RANGE
    Then B queda con Inmovilizado == true durante DURACION_ATURDIMIENTO
    And B no puede moverse ni atacar durante el aturdimiento

  Scenario: Un reinicio de ronda nunca deja al cliente bloqueado
    Given un jugador está inmovilizado por un pale
    When IdRonda cambia (reinicio entre rondas)
    Then todos los clientes reciben DESBLOQUEAR_MOVIMIENTO
    And ningún jugador queda inmovilizado de forma permanente

  Scenario: Morir durante un bloqueo no deja al respawn congelado
    Given el perseguido A está saltando un pale y bloqueado por el servidor
    And el perseguidor B golpea a A durante el salto
    When A reaparece
    Then movimientoBloqueado de A es false
    And A puede moverse inmediatamente