extends Control

var points : float = 0.0

# --- PRODUCTION AUTOMATIQUE FLUIDE ---
var points_par_seconde_actif : bool = false 
var multiplicateur_auto : float = 0.0           
var prix_amelioration : int = 10            

# --- AMÉLIORATION VITESSE (BUTTON 3) ---
# Note : Avec ce système fluide, le Button3 (vitesse) n'a plus vraiment de sens 
# car on produit déjà en continu à chaque image. On va le laisser mais il servira de "Super Multiplicateur" !
var prix_vitesse : int = 10   
var multiplicateur_vitesse : float = 1.0

# --- COMPÉTENCE AMÉLIORABLE : BOOSTER (BUTTON 4) ---
var puissance_booster : float = 0.0  
var prix_booster : int = 100         

func _ready() -> void:
	$Button2.text = "Auto-clic (Prix: " + str(prix_amelioration) + ")"
	$Button3.text = "Super Multi (Prix: " + str(prix_vitesse) + ")"
	$Button4.text = "Booster Multi (Prix: " + str(prix_booster) + ")"
	$Button4.visible = false 

func _process(delta: float) -> void:
	# 1. GESTION DU BOOSTER PROGRESSIF
	if puissance_booster > 0.0:
		multiplicateur_auto += puissance_booster * delta
		$Button2.text = "Auto-clic (+" + str(snapped(multiplicateur_auto, 0.1)) + ") - Prix: " + str(prix_amelioration)

	# 2. LE SECRET DU DÉFILEMENT CONTINU :
	# Au lieu d'attendre 1 seconde complète, on ajoute une fraction de points à CHAQUE IMAGE !
	if points_par_seconde_actif:
		# Points gagnés à cette image = (vitesse de prod * le temps de l'image) * le modificateur de vitesse
		var points_gagnes_ce_frame = (multiplicateur_auto * delta) * multiplicateur_vitesse
		points += points_gagnes_ce_frame
	
	# On rafraîchit l'affichage en continu à chaque image dès que l'auto-clic tourne
	if points_par_seconde_actif:
		%Label2.text = "%.1f" % points

# BOUTON 1 : Clic manuel
func _on_button_pressed() -> void:
	points += 1.0
	%Label2.text = "%.1f" % points

# BOUTON 2 : Augmente le multiplicateur manuellement
func _on_button_2_pressed() -> void:
	if points >= prix_amelioration:
		points -= prix_amelioration 
		points_par_seconde_actif = true
		multiplicateur_auto += 1.0 
		
		prix_amelioration = int(prix_amelioration * 1.5) + 5
		%Label2.text = "%.1f" % points
		$Button2.text = "Auto-clic (+" + str(snapped(multiplicateur_auto, 0.1)) + ") - Prix: " + str(prix_amelioration)
		
		if multiplicateur_auto >= 10.0 and not $Button4.visible:
			$Button4.visible = true

# BOUTON 3 : Devient un multiplicateur global de production
func _on_button_3_pressed() -> void:
	if points >= prix_vitesse:
		points -= prix_vitesse
		
		# Augmente la production globale de 20%
		multiplicateur_vitesse += 0.2
		prix_vitesse = int(prix_vitesse * 2.0)
		
		$Button3.text = "Super Multi (x" + str(snapped(multiplicateur_vitesse, 0.1)) + ") - Prix: " + str(prix_vitesse)
		%Label2.text = "%.1f" % points

# BOUTON 4 : Le Booster améliorable
func _on_button_4_pressed() -> void:
	if points >= prix_booster:
		points -= prix_booster
		puissance_booster += 0.10
		prix_booster = prix_booster * 2
		
		%Label2.text = "%.1f" % points
		$Button4.text = "Booster (+" + str(snapped(puissance_booster + 0.10, 0.1)) + "/s) - Prix: " + str(prix_booster)
