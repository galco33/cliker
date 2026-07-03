extends Control

# --- RESSOURCES ---
var points : float = 0.0
var tomates : float = 0.0 
var bois : float = 0.0

# --- PRODUCTION AUTOMATIQUE DES POINTS ---
var points_par_seconde_actif : bool = false 
var multiplicateur_auto : int = 0           
var prix_amelioration : int = 10            

var prix_vitesse : int = 10 
var multiplicateur_vitesse : float = 1.0

# --- LE BOOSTER ---
var puissance_booster : float = 0.0  
var prix_booster : int = 100         

# --- SYSTÈME DE TOMATES ---
var niveau_marchant : int = 0
var prix_perso_tomate : int = 1500 
var tomates_par_clic : int = 1

var niveau_tomate_auto : int = 0
var prix_points_perso_auto : int = 1000     
var prix_tomates_perso_auto : int = 10      

# --- SYSTÈME DE BOIS ---
var niveau_marchant_bois : int = 0
var prix_points_bois : int = 3000
var prix_tomates_bois : int = 100
var bois_par_clic : int = 1

var niveau_bois_auto : int = 0
var prix_points_bois_auto : int = 2000
var prix_bois_auto : int = 10

func _ready() -> void:
	$Button2.text = "Auto-clic (Prix: " + str(prix_amelioration) + ")"
	$Button3.text = "Super Multi (Prix: " + str(prix_vitesse) + ")"
	$Button4.text = "Booster Multi (Prix: " + str(prix_booster) + ")"
	
	$MarchantTomate.text = "Recruter Marchand (Prix: " + str(prix_perso_tomate) + " pts)"
	$ButtonTomate.text = "Acheter Tomates (Prix: 5 pts)"
	$TomateAuto.text = "Recruter Tomate Auto (Prix: " + str(prix_points_perso_auto) + " pts + " + str(prix_tomates_perso_auto) + " tomates)"
	
	# Initialisation sécurisée des textes du Bois
	if has_node("MarchantBois"):
		$MarchantBois.text = "Recruter Bûcheron (Prix: " + str(prix_points_bois) + " pts + " + str(prix_tomates_bois) + " tmt)"
	if has_node("ButtonBois"):
		$ButtonBois.text = "Couper Bois (Prix: 10 pts)"
	if has_node("BoisAuto"):
		$BoisAuto.text = "Recruter Bois Auto (Prix: " + str(prix_points_bois_auto) + " pts + " + str(prix_bois_auto) + " bois)"
	
	$Button4.visible = false 
	$MarchantTomate.visible = false 
	$ButtonTomate.visible = false 
	$TomateAuto.visible = false 
	
	if has_node("MarchantBois"): $MarchantBois.visible = false
	if has_node("ButtonBois"): $ButtonBois.visible = false
	if has_node("BoisAuto"): $BoisAuto.visible = false
	
	%LabelTomate.visible = false
	%LabelTomate.text = "Tomates: 0"
	
	if has_node("%LabelBois"):
		%LabelBois.visible = false
		%LabelBois.text = "Bois: 0"
	
	# CONFIGURATION DU MENU DE DEV
	if has_node("MenuDev"):
		$MenuDev.visible = false
		
		# On remplit le menu déroulant s'il existe
		if has_node("MenuDev/ChoixRessource"):
			var menu_choix = $MenuDev/ChoixRessource
			menu_choix.clear()
			menu_choix.add_item("Points")   # Index 0
			menu_choix.add_item("Tomates")  # Index 1
			menu_choix.add_item("Bois")     # Index 2

func _process(delta: float) -> void:
	# 1. PRODUCTION DE POINTS EN CONTINU
	if points_par_seconde_actif:
		var total_production = multiplicateur_auto + puissance_booster
		points += (total_production * delta) * multiplicateur_vitesse
		%Label2.text = "%.1f" % points
		
		if points >= 1500.0 and niveau_marchant == 0 and not $MarchantTomate.visible:
			$MarchantTomate.visible = true
			%LabelTomate.visible = true

	if niveau_marchant > 0 and niveau_tomate_auto == 0 and not $TomateAuto.visible:
		if points >= 1000.0 and tomates >= 10.0:
			$TomateAuto.visible = true

	if tomates >= 100.0 and points >= 3000.0 and niveau_marchant_bois == 0 and has_node("MarchantBois") and not $MarchantBois.visible:
		$MarchantBois.visible = true
		if has_node("%LabelBois"):
			%LabelBois.visible = true

	if niveau_marchant_bois > 0 and niveau_bois_auto == 0 and has_node("BoisAuto") and not $BoisAuto.visible:
		if points >= 2000.0 and bois >= 10.0:
			$BoisAuto.visible = true

	# 2. PRODUCTIONS AUTOMATIQUES
	if niveau_tomate_auto > 0:
		tomates += (1.0 * niveau_tomate_auto) * delta 
		%LabelTomate.text = "Tomates: " + str(floor(tomates))

	if niveau_bois_auto > 0:
		bois += (1.0 * niveau_bois_auto) * delta
		if has_node("%LabelBois"):
			%LabelBois.text = "Bois: " + str(floor(bois))

# BOUTON 1 : Clic manuel
func _on_button_pressed() -> void:
	points += 1.0
	%Label2.text = "%.1f" % points
	
	if points >= 1500.0 and niveau_marchant == 0 and not $MarchantTomate.visible:
		$MarchantTomate.visible = true
		%LabelTomate.visible = true

# BOUTON 2 : Auto-clic (MAX +20)
func _on_button_2_pressed() -> void:
	if multiplicateur_auto >= 20: return
	if points >= prix_amelioration:
		points -= prix_amelioration 
		points_par_seconde_actif = true
		multiplicateur_auto += 1 
		prix_amelioration = int(prix_amelioration * 1.5) + 5
		%Label2.text = "%.1f" % points
		
		if multiplicateur_auto >= 20:
			$Button2.text = "Auto-clic (+20) - MAX"
			$Button2.disabled = true
		else:
			$Button2.text = "Auto-clic (+" + str(multiplicateur_auto) + ") - Prix: " + str(prix_amelioration)
		
		if multiplicateur_auto >= 10 and not $Button4.visible:
			$Button4.visible = true

# BOUTON 3 : Super Multi (MAX x5)
func _on_button_3_pressed() -> void:
	if multiplicateur_vitesse >= 5.0: return
	if points >= prix_vitesse:
		points -= prix_vitesse
		multiplicateur_vitesse += 0.2
		prix_vitesse = int(prix_vitesse * 2.0)
		%Label2.text = "%.1f" % points
		
		if multiplicateur_vitesse >= 5.0:
			multiplicateur_vitesse = 5.0
			$Button3.text = "Super Multi (x5.0) - MAX"
			$Button3.disabled = true
		else:
			$Button3.text = "Super Multi (x" + str(snapped(multiplicateur_vitesse, 0.1)) + ") - Prix: " + str(prix_vitesse)

# BOUTON 4 : Booster (MAX +1.0/s)
func _on_button_4_pressed() -> void:
	if puissance_booster >= 1.0: return
	if points >= prix_booster:
		points -= prix_booster
		puissance_booster += 0.10
		prix_booster = prix_booster * 2
		%Label2.text = "%.1f" % points
		
		if puissance_booster >= 1.0:
			puissance_booster = 1.0
			$Button4.text = "Booster (+1.0/s) - MAX"
			$Button4.disabled = true
		else:
			$Button4.text = "Booster (+" + str(snapped(puissance_booster + 0.10, 0.1)) + "/s) - Prix: " + str(prix_booster)


# =========================================================
# 🍅 ZONE DES TOMATES
# =========================================================

func _on_marchant_tomate_pressed() -> void:
	if niveau_marchant >= 10: return
	if points >= prix_perso_tomate:
		points -= prix_perso_tomate
		niveau_marchant += 1
		tomates_par_clic = niveau_marchant
		$ButtonTomate.visible = true
		prix_perso_tomate = int(prix_perso_tomate * 1.8)
		%Label2.text = "%.1f" % points
		
		if niveau_marchant >= 10:
			$MarchantTomate.text = "Marchand (Lv. 10) - MAX"
			$MarchantTomate.disabled = true
		else:
			$MarchantTomate.text = "Améliorer Marchand (Lv. " + str(niveau_marchant) + ") - Prix: " + str(prix_perso_tomate) + " pts"
			$ButtonTomate.text = "Acheter Tomates (+" + str(tomates_par_clic) + " / Prix: 5 pts)"

func _on_button_tomate_pressed() -> void:
	if points >= 5:
		points -= 5
		tomates += tomates_par_clic
		%Label2.text = "%.1f" % points
		%LabelTomate.text = "Tomates: " + str(floor(tomates))

func _on_tomate_auto_pressed() -> void:
	if niveau_tomate_auto >= 10: return
	if points >= prix_points_perso_auto and tomates >= prix_tomates_perso_auto:
		points -= prix_points_perso_auto
		tomates -= prix_tomates_perso_auto
		niveau_tomate_auto += 1
		
		prix_points_perso_auto = int(prix_points_perso_auto * 1.5)
		prix_tomates_perso_auto = int(prix_tomates_perso_auto * 1.5)
		
		%Label2.text = "%.1f" % points
		%LabelTomate.text = "Tomates: " + str(floor(tomates))
		
		if niveau_tomate_auto >= 10:
			$TomateAuto.text = "Tomate Auto (Lv. 10) - MAX"
			$TomateAuto.disabled = true
		else:
			$TomateAuto.text = "Améliorer Tomate Auto (Lv. " + str(niveau_tomate_auto) + ") - Prix: " + str(prix_points_perso_auto) + " pts + " + str(prix_tomates_perso_auto) + " tmt"


# =========================================================
# 🪵 ZONE DU BOIS
# =========================================================

func _on_marchant_bois_pressed() -> void:
	if niveau_marchant_bois >= 10: return
	if points >= prix_points_bois and tomates >= prix_tomates_bois:
		points -= prix_points_bois
		tomates -= prix_tomates_bois
		
		niveau_marchant_bois += 1
		bois_par_clic = niveau_marchant_bois
		$ButtonBois.visible = true
		
		prix_points_bois = int(prix_points_bois * 1.8)
		prix_tomates_bois = int(prix_tomates_bois * 1.8)
		
		%Label2.text = "%.1f" % points
		%LabelTomate.text = "Tomates: " + str(floor(tomates))
		
		if niveau_marchant_bois >= 10:
			$MarchantBois.text = "Bûcheron (Lv. 10) - MAX"
			$MarchantBois.disabled = true
		else:
			$MarchantBois.text = "Améliorer Bûcheron (Lv. " + str(niveau_marchant_bois) + ") - Prix: " + str(prix_points_bois) + " pts + " + str(prix_tomates_bois) + " tmt"
			$ButtonBois.text = "Couper Bois (+" + str(bois_par_clic) + " / Prix: 10 pts)"

func _on_button_bois_pressed() -> void:
	if points >= 10:
		points -= 10
		bois += bois_par_clic
		%Label2.text = "%.1f" % points
		if has_node("%LabelBois"):
			%LabelBois.text = "Bois: " + str(floor(bois))

func _on_bois_auto_pressed() -> void:
	if niveau_bois_auto >= 10: return
	if points >= prix_points_bois_auto and bois >= prix_bois_auto:
		points -= prix_points_bois_auto
		bois -= prix_bois_auto
		niveau_bois_auto += 1
		
		prix_points_bois_auto = int(prix_points_bois_auto * 1.5)
		prix_bois_auto = int(prix_bois_auto * 1.5)
		
		%Label2.text = "%.1f" % points
		if has_node("%LabelBois"):
			%LabelBois.text = "Bois: " + str(floor(bois))
		
		if niveau_bois_auto >= 10:
			$BoisAuto.text = "Bois Auto (Lv. 10) - MAX"
			$BoisAuto.disabled = true
		else:
			$BoisAuto.text = "Améliorer Bois Auto (Lv. " + str(niveau_bois_auto) + ") - Prix: " + str(prix_points_bois_auto) + " pts + " + str(prix_bois_auto) + " bois"


# =========================================================
# 🛠️ INTERFACE DE DEV (MENU DE CHEAT AVEC CHOIX)
# =========================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_T and event.pressed:
		if has_node("MenuDev"):
			$MenuDev.visible = !$MenuDev.visible

func _on_button_give_pressed() -> void:
	var input_node = get_node("MenuDev/InputPoints")
	var menu_choix = get_node("MenuDev/ChoixRessource")
	
	if input_node and menu_choix:
		var texte = input_node.text
		if texte == "": return
			
		var montant = float(texte)
		if montant > 0:
			# On regarde quel index est sélectionné dans le menu déroulant
			var ressource_selectionnee = menu_choix.selected
			
			match ressource_selectionnee:
				0: # Points
					points += montant
					%Label2.text = "%.1f" % points
					print("Cheat : +", montant, " points !")
				1: # Tomates
					tomates += montant
					%LabelTomate.text = "Tomates: " + str(floor(tomates))
					print("Cheat : +", montant, " tomates !")
				2: # Bois
					bois += montant
					if has_node("%LabelBois"):
						%LabelBois.text = "Bois: " + str(floor(bois))
					print("Cheat : +", montant, " bois !")
			
			input_node.text = ""           
			$MenuDev.visible = false
