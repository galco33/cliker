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
	# Masquer les éléments avancés au lancement du jeu
	if has_node("Button4"): $Button4.visible = false 
	if has_node("MarchantTomate"): $MarchantTomate.visible = false 
	if has_node("ButtonTomate"): $ButtonTomate.visible = false 
	if has_node("TomateAuto"): $TomateAuto.visible = false 
	
	if has_node("MarchantBois"): $MarchantBois.visible = false
	if has_node("ButtonBois"): $ButtonBois.visible = false
	if has_node("BoisAuto"): $BoisAuto.visible = false
	
	if has_node("%LabelTomate"): %LabelTomate.visible = false
	if has_node("%LabelBois"): %LabelBois.visible = false
	
	# Configuration initiale de l'affichage de l'UI
	_update_ui()
	
	# CONFIGURATION DU MENU DE DEV
	if has_node("MenuDev"):
		$MenuDev.visible = false
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
		
	# 2. PRODUCTIONS AUTOMATIQUES DE RESSOURCES
	if niveau_tomate_auto > 0:
		tomates += (1.0 * niveau_tomate_auto) * delta 

	if niveau_bois_auto > 0:
		bois += (1.0 * niveau_bois_auto) * delta

	# 3. VÉRIFICATION DES SEUILS DE DÉBLOCAGE PROGRESSIF
	if points >= 1500.0 and niveau_marchant == 0:
		if has_node("MarchantTomate"): $MarchantTomate.visible = true
		if has_node("%LabelTomate"): %LabelTomate.visible = true

	if niveau_marchant > 0 and niveau_tomate_auto == 0:
		if points >= 1000.0 and tomates >= 10.0 and has_node("TomateAuto"):
			$TomateAuto.visible = true

	if tomates >= 100.0 and points >= 3000.0 and niveau_marchant_bois == 0:
		if has_node("MarchantBois"): $MarchantBois.visible = true
		if has_node("%LabelBois"): %LabelBois.visible = true

	if niveau_marchant_bois > 0 and niveau_bois_auto == 0:
		if points >= 2000.0 and bois >= 10.0 and has_node("BoisAuto"):
			$BoisAuto.visible = true

	# Mise à jour continue de l'UI pour voir les compteurs grimper avec le delta time
	_update_ui()

# --- FONCTION CENTRALE DE MISE À JOUR DE L'INTERFACE ---
func _update_ui() -> void:
	# Actualisation des compteurs textuels principaux
	if has_node("%Label2"): %Label2.text = "%.1f" % points
	if has_node("%LabelTomate"): %LabelTomate.text = "Tomates: " + str(floor(tomates))
	if has_node("%LabelBois"): %LabelBois.text = "Bois: " + str(floor(bois))
	
	# --- TES PHRASES PERSONNALISÉES SUR LES BOUTONS ---
	
	# Bouton "ajout 1" (Button2)
	if has_node("Button2"):
		if multiplicateur_auto >= 20:
			$Button2.text = "ajout 1 (+20) - MAX"
			$Button2.disabled = true
		else:
			# Affiche la prochaine valeur (+1) et le prix calculé
			$Button2.text = "ajout 1 (+" + str(multiplicateur_auto + 1) + ") - Prix: " + str(prix_amelioration)
			
	# Bouton "vitesse +" (Button3)
	if has_node("Button3"):
		if multiplicateur_vitesse >= 5.0:
			$Button3.text = "vitesse + (x5.0) - MAX"
			$Button3.disabled = true
		else:
			# Affiche le prochain palier de vitesse (+0.2) et son prix
			$Button3.text = "vitesse + (x" + str(snapped(multiplicateur_vitesse + 0.2, 0.1)) + ") - Prix: " + str(prix_vitesse)
			
	# Bouton "bosster" (Button4)
	if has_node("Button4"):
		if puissance_booster >= 1.0:
			$Button4.text = "bosster (+1.0/s) - MAX"
			$Button4.disabled = true
		else:
			# Affiche le prochain bonus de booster (+0.10) et son prix
			$Button4.text = "bosster (+" + str(snapped(puissance_booster + 0.10, 0.1)) + "/s) - Prix: " + str(prix_booster)

	# --- INTERFACE DES TOMATES ---
	if has_node("MarchantTomate"):
		if niveau_marchant >= 10:
			$MarchantTomate.text = "Marchand (Lv. 10) - MAX"
			$MarchantTomate.disabled = true
		else:
			$MarchantTomate.text = "Recruter Marchand (Prix: " + str(prix_perso_tomate) + " pts)"
			
	if has_node("ButtonTomate"):
		$ButtonTomate.text = "Acheter Tomates (+" + str(tomates_par_clic) + " / Prix: 5 pts)"
		
	if has_node("TomateAuto"):
		if niveau_tomate_auto >= 10:
			$TomateAuto.text = "Tomate Auto (Lv. 10) - MAX"
			$TomateAuto.disabled = true
		else:
			$TomateAuto.text = "Recruter Tomate Auto (Prix: " + str(prix_points_perso_auto) + " pts + " + str(prix_tomates_perso_auto) + " tomates)"

	# --- INTERFACE DU BOIS ---
	if has_node("MarchantBois"):
		if niveau_marchant_bois >= 10:
			$MarchantBois.text = "Bûcheron (Lv. 10) - MAX"
			$MarchantBois.disabled = true
		else:
			$MarchantBois.text = "Recruter Bûcheron (Prix: " + str(prix_points_bois) + " pts + " + str(prix_tomates_bois) + " tmt)"
			
	if has_node("ButtonBois"):
		$ButtonBois.text = "Couper Bois (+" + str(bois_par_clic) + " / Prix: 10 pts)"
		
	if has_node("BoisAuto"):
		if niveau_bois_auto >= 10:
			$BoisAuto.text = "Bois Auto (Lv. 10) - MAX"
			$BoisAuto.disabled = true
		else:
			$BoisAuto.text = "Recruter Bois Auto (Prix: " + str(prix_points_bois_auto) + " pts + " + str(prix_bois_auto) + " bois)"

# BOUTON 1 : Clic manuel principal ("clik me")
func _on_button_pressed() -> void:
	points += 1.0
	_update_ui()

# BOUTON 2 : Actionneur du bouton "ajout 1"
func _on_button_2_pressed() -> void:
	if multiplicateur_auto >= 20: return
	if points >= prix_amelioration:
		points -= prix_amelioration 
		points_par_seconde_actif = true
		multiplicateur_auto += 1 
		prix_amelioration = int(prix_amelioration * 1.5) + 5
		
		# Fait apparaître le bouton bosster dès que l'auto-clic atteint le niveau 10
		if multiplicateur_auto >= 10 and has_node("Button4") and not $Button4.visible:
			$Button4.visible = true
			
		_update_ui()

# BOUTON 3 : Actionneur du bouton "vitesse +"
func _on_button_3_pressed() -> void:
	if multiplicateur_vitesse >= 5.0: return
	if points >= prix_vitesse:
		points -= prix_vitesse
		multiplicateur_vitesse += 0.2
		prix_vitesse = int(prix_vitesse * 2.0)
		if multiplicateur_vitesse >= 5.0:
			multiplicateur_vitesse = 5.0
		_update_ui()

# BOUTON 4 : Actionneur du bouton "bosster"
func _on_button_4_pressed() -> void:
	if puissance_booster >= 1.0: return
	if points >= prix_booster:
		points -= prix_booster
		puissance_booster += 0.10
		prix_booster = prix_booster * 2
		if puissance_booster >= 1.0:
			puissance_booster = 1.0
		_update_ui()

# =========================================================
# 🍅 ZONE DES TOMATES
# =========================================================

func _on_marchant_tomate_pressed() -> void:
	if niveau_marchant >= 10: return
	if points >= prix_perso_tomate:
		points -= prix_perso_tomate
		niveau_marchant += 1
		tomates_par_clic = niveau_marchant
		if has_node("ButtonTomate"): $ButtonTomate.visible = true
		prix_perso_tomate = int(prix_perso_tomate * 1.8)
		_update_ui()

func _on_button_tomate_pressed() -> void:
	if points >= 5:
		points -= 5
		tomates += tomates_par_clic
		_update_ui()

func _on_tomate_auto_pressed() -> void:
	if niveau_tomate_auto >= 10: return
	if points >= prix_points_perso_auto and tomates >= prix_tomates_perso_auto:
		points -= prix_points_perso_auto
		tomates -= prix_tomates_perso_auto
		niveau_tomate_auto += 1
		
		prix_points_perso_auto = int(prix_points_perso_auto * 1.5)
		prix_tomates_perso_auto = int(prix_tomates_perso_auto * 1.5)
		_update_ui()

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
		if has_node("ButtonBois"): $ButtonBois.visible = true
		
		prix_points_bois = int(prix_points_bois * 1.8)
		prix_tomates_bois = int(prix_tomates_bois * 1.8)
		_update_ui()

func _on_button_bois_pressed() -> void:
	if points >= 10:
		points -= 10
		bois += bois_par_clic
		_update_ui()

func _on_bois_auto_pressed() -> void:
	if niveau_bois_auto >= 10: return
	if points >= prix_points_bois_auto and bois >= prix_bois_auto:
		points -= prix_points_bois_auto
		bois -= prix_bois_auto
		niveau_bois_auto += 1
		
		prix_points_bois_auto = int(prix_points_bois_auto * 1.5)
		prix_bois_auto = int(prix_bois_auto * 1.5)
		_update_ui()

# =========================================================
# 🛠️ INTERFACE DE DEV (MENU DE CHEAT)
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
			var ressource_selectionnee = menu_choix.selected
			
			match ressource_selectionnee:
				0: # Points
					points += montant
					print("Cheat : +", montant, " points !")
				1: # Tomates
					tomates += montant
					print("Cheat : +", montant, " tomates !")
				2: # Bois
					bois += montant
					print("Cheat : +", montant, " bois !")
			
			input_node.text = ""           
			$MenuDev.visible = false 
			_update_ui()
