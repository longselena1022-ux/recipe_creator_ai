String emojiForIngredient(String name) {
  final n = name.toLowerCase();

  // Compound terms first to avoid being captured by their parts.
  if (n.contains('peanut butter')) return '🥜';
  if (n.contains('ice cream')) return '🍦';
  if (n.contains('sweet potato') || n.contains('yam')) return '🍠';
  if (n.contains('olive oil')) return '🫒';
  if (n.contains('soy sauce') || n.contains('soya sauce')) return '🍶';
  if (n.contains('hot sauce') || n.contains('chili sauce') || n.contains('sriracha')) {
    return '🌶️';
  }
  if (n.contains('tomato sauce') || n.contains('marinara') || n.contains('ketchup')) {
    return '🥫';
  }
  if (n.contains('hot dog') || n.contains('frankfurter') || n.contains('sausage')) {
    return '🌭';
  }

  // Vegetables (eggplant before egg; chili before pepper).
  if (n.contains('eggplant') || n.contains('aubergine')) return '🍆';
  if (n.contains('tomato')) return '🍅';
  if (n.contains('chili') ||
      n.contains('chilli') ||
      n.contains('chile') ||
      n.contains('jalapeno') ||
      n.contains('jalapeño') ||
      n.contains('habanero') ||
      n.contains('cayenne') ||
      n.contains('paprika')) {
    return '🌶️';
  }
  if (n.contains('bell pepper') || n.contains('capsicum') || n.contains('pepper')) {
    return '🫑';
  }
  if (n.contains('broccoli')) return '🥦';
  if (n.contains('cabbage') ||
      n.contains('lettuce') ||
      n.contains('spinach') ||
      n.contains('kale') ||
      n.contains('arugula') ||
      n.contains('bok choy') ||
      n.contains('chard') ||
      n.contains('greens')) {
    return '🥬';
  }
  if (n.contains('cucumber') ||
      n.contains('pickle') ||
      n.contains('zucchini') ||
      n.contains('courgette')) {
    return '🥒';
  }
  if (n.contains('carrot')) return '🥕';
  if (n.contains('corn') || n.contains('maize')) return '🌽';
  if (n.contains('onion') ||
      n.contains('shallot') ||
      n.contains('leek') ||
      n.contains('scallion') ||
      n.contains('chive')) {
    return '🧅';
  }
  if (n.contains('garlic')) return '🧄';
  if (n.contains('potato') || n.contains('spud')) return '🥔';
  if (n.contains('mushroom') ||
      n.contains('shiitake') ||
      n.contains('portobello') ||
      n.contains('cremini') ||
      n.contains('porcini') ||
      n.contains('truffle')) {
    return '🍄';
  }
  if (n.contains('avocado') || n.contains('guacamole')) return '🥑';
  if (n.contains('ginger')) return '🫚';
  if (n.contains('olive')) return '🫒';
  if (n.contains('asparagus') ||
      n.contains('parsley') ||
      n.contains('cilantro') ||
      n.contains('coriander') ||
      n.contains('basil') ||
      n.contains('mint') ||
      n.contains('rosemary') ||
      n.contains('thyme') ||
      n.contains('oregano') ||
      n.contains('sage') ||
      n.contains('dill') ||
      n.contains('herb')) {
    return '🌿';
  }

  // Fruits (peach/pear/peanut before any short 'pea' match; grapefruit before grape).
  if (n.contains('apple')) return '🍎';
  if (n.contains('banana') || n.contains('plantain')) return '🍌';
  if (n.contains('grapefruit')) return '🍊';
  if (n.contains('grape') || n.contains('raisin')) return '🍇';
  if (n.contains('strawberr')) return '🍓';
  if (n.contains('blueberr') ||
      n.contains('raspberr') ||
      n.contains('blackberr') ||
      n.contains('cranberr') ||
      n.contains('berry') ||
      n.contains('berries')) {
    return '🫐';
  }
  if (n.contains('cherry') || n.contains('cherries')) return '🍒';
  if (n.contains('peach') || n.contains('apricot') || n.contains('nectarine')) {
    return '🍑';
  }
  if (n.contains('pear') && !n.contains('pearl')) return '🍐';
  if (n.contains('orange') ||
      n.contains('mandarin') ||
      n.contains('clementine') ||
      n.contains('tangerine')) {
    return '🍊';
  }
  if (n.contains('lemon') || n.contains('lime')) return '🍋';
  if (n.contains('mango')) return '🥭';
  if (n.contains('pineapple')) return '🍍';
  if (n.contains('coconut')) return '🥥';
  if (n.contains('watermelon')) return '🍉';
  if (n.contains('melon') || n.contains('cantaloupe') || n.contains('honeydew')) {
    return '🍈';
  }
  if (n.contains('kiwi')) return '🥝';

  // Proteins — meat & seafood.
  if (n.contains('bacon')) return '🥓';
  if (n.contains('chicken') || n.contains('poultry')) return '🍗';
  if (n.contains('turkey')) return '🦃';
  if (n.contains('steak') ||
      n.contains('beef') ||
      n.contains('ribeye') ||
      n.contains('sirloin') ||
      n.contains('brisket')) {
    return '🥩';
  }
  if (n.contains('pork') ||
      n.contains('ham') ||
      n.contains('lamb') ||
      n.contains('mutton') ||
      n.contains('veal') ||
      n.contains('meat')) {
    return '🍖';
  }
  if (n.contains('shrimp') || n.contains('prawn')) return '🍤';
  if (n.contains('lobster')) return '🦞';
  if (n.contains('crab')) return '🦀';
  if (n.contains('squid') || n.contains('octopus') || n.contains('calamari')) {
    return '🦑';
  }
  if (n.contains('oyster') ||
      n.contains('clam') ||
      n.contains('mussel') ||
      n.contains('scallop')) {
    return '🦪';
  }
  if (n.contains('salmon') ||
      n.contains('tuna') ||
      n.contains('cod') ||
      n.contains('tilapia') ||
      n.contains('trout') ||
      n.contains('mackerel') ||
      n.contains('halibut') ||
      n.contains('anchov') ||
      n.contains('sardine') ||
      n.contains('fish')) {
    return '🐟';
  }

  // Dairy & eggs.
  if (n.contains('butter')) return '🧈';
  if (n.contains('cheese') ||
      n.contains('cheddar') ||
      n.contains('mozzarella') ||
      n.contains('parmesan') ||
      n.contains('feta') ||
      n.contains('ricotta') ||
      n.contains('gouda') ||
      n.contains('brie') ||
      n.contains('gruyere')) {
    return '🧀';
  }
  if (n.contains('yogurt') || n.contains('yoghurt')) return '🥛';
  if (n.contains('cream')) return '🥛';
  if (n.contains('milk')) return '🥛';
  if (n.contains('egg')) return '🥚';

  // Grains, breads, pasta.
  if (n.contains('bagel')) return '🥯';
  if (n.contains('croissant')) return '🥐';
  if (n.contains('baguette')) return '🥖';
  if (n.contains('bread') ||
      n.contains('toast') ||
      n.contains('bun') ||
      n.contains(' roll') ||
      n.contains('tortilla') ||
      n.contains('pita') ||
      n.contains('naan')) {
    return '🍞';
  }
  if (n.contains('pasta') ||
      n.contains('noodle') ||
      n.contains('spaghetti') ||
      n.contains('linguine') ||
      n.contains('fettuccine') ||
      n.contains('penne') ||
      n.contains('macaroni') ||
      n.contains('lasagna') ||
      n.contains('ramen') ||
      n.contains('udon')) {
    return '🍝';
  }
  if (n.contains('rice')) return '🍚';
  if (n.contains('oat') ||
      n.contains('barley') ||
      n.contains('wheat') ||
      n.contains('flour') ||
      n.contains('quinoa') ||
      n.contains('cereal') ||
      n.contains('grain')) {
    return '🌾';
  }

  // Legumes, nuts, seeds.
  if (n.contains('peanut')) return '🥜';
  if (n.contains('almond') ||
      n.contains('walnut') ||
      n.contains('cashew') ||
      n.contains('pistachio') ||
      n.contains('pecan') ||
      n.contains('hazelnut') ||
      n.contains('macadamia') ||
      n.contains('nut')) {
    return '🌰';
  }
  if (n.contains('bean') ||
      n.contains('lentil') ||
      n.contains('chickpea') ||
      n.contains('garbanzo') ||
      n.contains('legume') ||
      n.contains('tofu') ||
      n.contains('edamame') ||
      n.contains('peas')) {
    return '🫘';
  }

  // Sweets, sugars, sauces.
  if (n.contains('chocolate') || n.contains('cocoa') || n.contains('cacao')) {
    return '🍫';
  }
  if (n.contains('honey')) return '🍯';
  if (n.contains('sugar') || n.contains('candy') || n.contains('sweetener')) {
    return '🍬';
  }
  if (n.contains('salt')) return '🧂';
  if (n.contains('canned') || n.contains('soup')) return '🥫';
  if (n.contains('vinegar') || n.contains('mirin') || n.contains('sake')) {
    return '🍶';
  }

  // Drinks.
  if (n.contains('coffee') || n.contains('espresso')) return '☕';
  if (n.contains('matcha') || n.contains('tea')) return '🍵';
  if (n.contains('wine')) return '🍷';
  if (n.contains('beer') || n.contains('ale') || n.contains('lager')) return '🍺';
  if (n.contains('juice')) return '🧃';
  if (n.contains('water')) return '💧';
  if (n.contains('ice')) return '🧊';

  return '🥗';
}
