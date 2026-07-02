extends Control

# --- RESSOURCES ---
var points : float = 0.0
var tomates : float = 0.0 

# --- PRODUCTION AUTOMATIQUE DES POINTS ---
var points_par_seconde_actif : bool = false 
var multiplicateur_auto : int = 0           
var prix_amelioration : int = 10            

var prix_vitesse : int = 10 
var multiplicateur_vitesse : float = 1.0

# --- LE BOOSTER ---
var puissance_booster : float = 0.0  
var prix_booster : int = 100         

# --- SYSTÈME DE PERSONNAGES & TOMATES ---
var a_perso_tomate : bool = false
var prix_perso_tomate : int = 1500 

var a_perso_tomate_auto : bool = false
var prix_points_perso_auto : int = 1000     
var prix_tomates_perso_auto : int = 10      

func _ready() -> void:
	$Button2.text = "Auto-clic (Prix: " + str(prix_amelioration) + ")"
	$Button3.text = "Super Multi (Prix: " + str(prix_vitesse) + ")"
	$Button4.text = "Booster Multi (Prix: " + str(prix_booster) + ")"
	
	$MarchantTomate.text = "Recruter Perso Tomate (Prix: " + str(prix_perso_tomate) + " pts)"
	$ButtonTomate.text = "Acheter 1 Tomate (Prix: 5 pts)"
	$TomateAuto.text = "Recruter Tomate Auto (Prix: " + str(prix_points_perso_auto) + " pts + " + str(prix_tomates_perso_auto) + " tomates)"
	
	$Button4.visible = false 
	$MarchantTomate.visible = false 
	$ButtonTomate.visible = false 
	$TomateAuto.visible = false 
	
	%LabelTomate.visible = false
	%LabelTomate.text = "Tomates: 0"

func _process(delta: float) -> void:
	# 1. PRODUCTION DE POINTS EN CONTINU
	if points_par_seconde_actif:
		var total_production = multiplicateur_auto + puissance_booster
		points += (total_production * delta) * multiplicateur_vitesse
		%Label2.text = "%.1f" % points
		
		# Règle 1 : Marchand invisible avant 1500 points
		if points >= 1500.0 and not a_perso_tomate and not $MarchantTomate.visible:
			$MarchantTomate.visible = true
			%LabelTomate.visible = true

	# Règle 3 : Tomate Auto invisible avant 10 tomates et 1000 points
	if a_perso_tomate and not a_perso_tomate_auto and not $TomateAuto.visible:
		if points >= 1000.0 and tomates >= 10.0:
			$TomateAuto.visible = true

	# 2. Production automatique de tomates
	if a_perso_tomate_auto:
		tomates += 1.0 * delta 
		%LabelTomate.text = "Tomates: " + str(floor(tomates))

# BOUTON 1 : Clic manuel
func _on_button_pressed() -> void:
	points += 1.0
	%Label2.text = "%.1f" % points
	
	if points >= 1500.0 and not a_perso_tomate and not $MarchantTomate.visible:
		$MarchantTomate.visible = true
		%LabelTomate.visible = true

# BOUTON 2 : Auto-clic (MAX +20)
func _on_button_2_pressed() -> void:
	# Si on est déjà au max, on ne fait rien
	if multiplicateur_auto >= 20:
		return
		
	if points >= prix_amelioration:
		points -= prix_amelioration 
		points_par_seconde_actif = true
		
		multiplicateur_auto += 1 
		prix_amelioration = int(prix_amelioration * 1.5) + 5
		%Label2.text = "%.1f" % points
		
		# Vérification du MAXIMUM
		if multiplicateur_auto >= 20:
			$Button2.text = "Auto-clic (+20) - MAX"
			$Button2.disabled = true # Grise le bouton
		else:
			$Button2.text = "Auto-clic (+" + str(multiplicateur_auto) + ") - Prix: " + str(prix_amelioration)
		
		if multiplicateur_auto >= 10 and not $Button4.visible:
			$Button4.visible = true

# BOUTON 3 : Super Multi (MAX x5)
func _on_button_3_pressed() -> void:
	# Si on est déjà au max (x5.0 ou plus), on bloque
	if multiplicateur_vitesse >= 5.0:
		return
		
	if points >= prix_vitesse:
		points -= prix_vitesse
		
		multiplicateur_vitesse += 0.2
		prix_vitesse = int(prix_vitesse * 2.0)
		%Label2.text = "%.1f" % points
		
		# Vérification du MAXIMUM
		if multiplicateur_vitesse >= 5.0:
			multiplicateur_vitesse = 5.0 # Sécurité pour ne pas dépasser à cause des arrondis decimals
			$Button3.text = "Super Multi (x5.0) - MAX"
			$Button3.disabled = true
		else:
			$Button3.text = "Super Multi (x" + str(snapped(multiplicateur_vitesse, 0.1)) + ") - Prix: " + str(prix_vitesse)

# BOUTON 4 : Booster (MAX +1.0/s)
func _on_button_4_pressed() -> void:
	# Si on est déjà au max, on bloque
	if puissance_booster >= 1.0:
		return
		
	if points >= prix_booster:
		points -= prix_booster
		
		puissance_booster += 0.10
		prix_booster = prix_booster * 2
		%Label2.text = "%.1f" % points
		
		# Vérification du MAXIMUM
		if puissance_booster >= 1.0:
			puissance_booster = 1.0
			$Button4.text = "Booster (+1.0/s) - MAX"
			$Button4.disabled = true
		else:
			$Button4.text = "Booster (+" + str(snapped(puissance_booster + 0.10, 0.1)) + "/s) - Prix: " + str(prix_booster)

# =========================================================
# LES BOUTONS DE COMPÉTENCES/PERSONNAGES
# =========================================================

func _on_marchant_tomate_pressed() -> void:
	if points >= prix_perso_tomate:
		points -= prix_perso_tomate
		a_perso_tomate = true
		$ButtonTomate.visible = true
		$MarchantTomate.text = "Perso Tomate RECRUTÉ !"
		$MarchantTomate.disabled = true
		%Label2.text = "%.1f" % points

func _on_button_tomate_pressed() -> void:
	if points >= 5:
		points -= 5
		tomates += 1
		%Label2.text = "%.1f" % points
		%LabelTomate.text = "Tomates: " + str(floor(tomates))

func _on_tomate_auto_pressed() -> void:
	if points >= prix_points_perso_auto and tomates >= prix_tomates_perso_auto:
		points -= prix_points_perso_auto
		tomates -= prix_tomates_perso_auto
		a_perso_tomate_auto = true
		%Label2.text = "%.1f" % points
		%LabelTomate.text = "Tomates: " + str(floor(tomates))
		$TomateAuto.text = "Tomate Auto RECRUTÉ !"
		$TomateAuto.disabled = true
