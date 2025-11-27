<?php

namespace Database\Seeders; // Corrected namespace

use App\Models\Category;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $categories = [
            [
                'name' => 'Mode & Beauté',
                'description' => 'Influenceurs spécialisés dans les tendances vestimentaires, le maquillage, les soins de la peau et les conseils beauté.',
            ],
            [
                'name' => 'Voyage & Aventure',
                'description' => 'Créateurs de contenu partageant des expériences de voyage, des guides de destination et des conseils d\'aventure.',
            ],
            [
                'name' => 'Cuisine & Gastronomie',
                'description' => 'Chefs, blogueurs culinaires et amateurs de gastronomie présentant des recettes, des critiques de restaurants et des astuces culinaires.',
            ],
            [
                'name' => 'Fitness & Bien-être',
                'description' => 'Experts en fitness, coaches sportifs et promoteurs d\'un mode de vie sain, partageant des routines d\'exercice, des conseils nutritionnels et des astuces de bien-être.',
            ],
            [
                'name' => 'Jeux Vidéo',
                'description' => 'Streamers, commentateurs et critiques de jeux vidéo, partageant des parties en direct, des analyses de jeux et des actualités de l\'industrie.',
            ],
            [
                'name' => 'Technologie & Innovations',
                'description' => 'Évaluateurs de gadgets, experts en nouvelles technologies et innovateurs présentant les dernières avancées technologiques et leurs avis.',
            ],
            [
                'name' => 'Maison & Décoration',
                'description' => 'Influenceurs dédiés à l\'aménagement intérieur, au design, au jardinage et aux projets de bricolage pour la maison.',
            ],
            [
                'name' => 'Famille & Parentalité',
                'description' => 'Parents partageant leur quotidien, leurs conseils éducatifs, des activités pour enfants et des retours sur les produits pour bébés et enfants.',
            ],
            [
                'name' => 'Éducation & Apprentissage',
                'description' => 'Formateurs, éducateurs et vulgarisateurs proposant des tutoriels, des cours en ligne et des conseils pour l\'apprentissage dans divers domaines.',
            ],
            [
                'name' => 'Photographie & Vidéographie',
                'description' => 'Artistes visuels partageant des techniques de prise de vue, des retouches photo/vidéo et des inspirations créatives.',
            ],
            [
                'name' => 'Art & Culture',
                'description' => 'Critiques d\'art, musiciens, danseurs et amateurs de culture partageant des découvertes artistiques, des performances et des discussions culturelles.',
            ],
            [
                'name' => 'Finance Personnelle',
                'description' => 'Experts en finance partageant des conseils sur l\'investissement, l\'épargne, la budgétisation et la gestion de patrimoine.',
            ],
        ];

        foreach ($categories as $category) {
            Category::create($category);
        }
    }
}
