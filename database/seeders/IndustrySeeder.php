<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Industry;

class IndustrySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $industries = [
            ['name' => 'Événementiel', 'description' => 'Gestion et organisation d\'événements.'],
            ['name' => 'Marketing Numérique', 'description' => 'Marketing des produits ou services utilisant les technologies numériques.'],
            ['name' => 'Mode et Beauté', 'description' => 'Industrie de la mode, des cosmétiques et des soins personnels.'],
            ['name' => 'Voyage et Tourisme', 'description' => 'Services liés aux voyages et au tourisme.'],
            ['name' => 'Gastronomie et Restauration', 'description' => 'Industrie de la nourriture et de la restauration.'],
            ['name' => 'Technologie et Gadgets', 'description' => 'Produits et services technologiques.'],
            ['name' => 'Santé et Bien-être', 'description' => 'Produits et services liés à la santé et au bien-être.'],
            ['name' => 'Divertissement', 'description' => 'Industrie du divertissement, y compris les films, la musique et les jeux.'],
            ['name' => 'Sport et Fitness', 'description' => 'Produits et services liés au sport et à la forme physique.'],
            ['name' => 'Automobile', 'description' => 'Industrie automobile, y compris les voitures et les motos.'],
            ['name' => 'Immobilier', 'description' => 'Services liés à l\'immobilier.'],
            ['name' => 'Finance et Assurance', 'description' => 'Services financiers et d\'assurance.'],
        ];

        foreach ($industries as $industry) {
            Industry::create($industry);
        }
    }
}