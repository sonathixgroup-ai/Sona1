// lib/presentation/thix_sante/patient/services/grossesse_advice_service.dart
import '../models/grossesse_model.dart';
class GrossesseAdviceService {
  static WeekAdvice getWeekAdvice(int sa){
    if(sa>=24) return WeekAdvice(
      title: 'Semaine $sa - Viabilité',
      babyDevelopment: ['Poumons continuent de produire du surfactant','Cerveau très actif, cycles veille/sommeil','Peau moins transparente, graisse se forme','Entend ta voix et réagit'],
      motherAdvice: ['Dors sur côté gauche','Surveille TA','Marche 30 min/j'],
      nutrition: ['Calcium 1000mg','Fer si anémie','Hydratation 2L','Oméga 3'],
      avoid: ['Viande crue','Poisson cru','Alcool','Tabac'],
    );
    if(sa<=12) return WeekAdvice(title: 'Semaine $sa - 1er trimestre', babyDevelopment: ['Organes se forment','Cœur bat','Bourgeons des membres'], motherAdvice: ['Repos','Acide folique obligatoire'], nutrition: ['Acide folique 400µg','Légumes verts'], avoid: ['Alcool','Médicaments sans avis','Radios']);
    return WeekAdvice(title: 'Semaine $sa', babyDevelopment: ['Croissance rapide','Mouvements plus forts'], motherAdvice: ['Écoute ton corps','Prépare valise dès 32 SA'], nutrition: ['Protéines','Fer','Calcium'], avoid: ['Excès sucre','Port de charges lourdes']);
  }
  static BabyWeekInfo getBabyInfo(int sa){
    if(sa>=40) return BabyWeekInfo(fruit:'Pastèque', size:'51 cm', weight:'3.4 kg', desc:'Prêt');
    if(sa>=36) return BabyWeekInfo(fruit:'Pastèque petite', size:'47 cm', weight:'2.6 kg', desc:'Tête en bas');
    if(sa>=32) return BabyWeekInfo(fruit:'Courge', size:'42 cm', weight:'1.7 kg', desc:'Os solides');
    if(sa>=24) return BabyWeekInfo(fruit:'Maïs', size:'30 cm', weight:'600 g', desc:'Poumons en développement');
    if(sa>=20) return BabyWeekInfo(fruit:'Banane', size:'25 cm', weight:'300 g', desc:'Coups');
    return BabyWeekInfo(fruit:'Citron', size:'6 cm', weight:'14 g', desc:'Organes formés');
  }
}
