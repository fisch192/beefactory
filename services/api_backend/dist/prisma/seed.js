"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
require("dotenv/config");
const client_1 = require("@prisma/client");
const adapter_pg_1 = require("@prisma/adapter-pg");
const pg_1 = __importDefault(require("pg"));
const bcrypt = __importStar(require("bcryptjs"));
const connectionString = process.env['DATABASE_URL'] ?? 'postgresql://localhost:5432/bee';
const pool = new pg_1.default.Pool({ connectionString });
const adapter = new adapter_pg_1.PrismaPg(pool);
const prisma = new client_1.PrismaClient({ adapter });
function generateWeeklyFocus(elevationBand) {
    const focus = {};
    const seasonOffset = elevationBand === 'low' ? 0 : elevationBand === 'mid' ? 2 : 4;
    for (let week = 1; week <= 52; week++) {
        const adjustedWeek = week - seasonOffset;
        if (adjustedWeek >= 1 && adjustedWeek <= 8) {
            focus[String(week)] = {
                title: 'Winterruhe',
                tasks: [
                    'Flugloch kontrollieren',
                    'Futtervorrat pruefen (Stockwaage)',
                    'Maeuseschutz kontrollieren',
                ],
                tips: [
                    'Voelker nicht stoeren',
                    'Bei Schneefall Flugloch freihalten',
                ],
            };
        }
        else if (adjustedWeek >= 9 && adjustedWeek <= 12) {
            focus[String(week)] = {
                title: 'Vorfrühling - Auswinterung',
                tasks: [
                    'Erster Reinigungsflug beobachten',
                    'Totenfall kontrollieren',
                    'Futtervorrat schaetzen',
                    'Notfuetterung bei Bedarf',
                ],
                tips: [
                    'Voelker nur kurz oeffnen',
                    'Auf Weiselrichtigkeit achten',
                ],
            };
        }
        else if (adjustedWeek >= 13 && adjustedWeek <= 16) {
            focus[String(week)] = {
                title: 'Frühjahrsentwicklung',
                tasks: [
                    'Erste Durchsicht durchfuehren',
                    'Brutnest beurteilen',
                    'Drohnenrahmen einhaengen',
                    'Raeumchen geben bei Bedarf',
                ],
                tips: [
                    'Volksentwicklung dokumentieren',
                    'Schwache Voelker vereinigen',
                ],
            };
        }
        else if (adjustedWeek >= 17 && adjustedWeek <= 20) {
            focus[String(week)] = {
                title: 'Schwarmzeit beginnt',
                tasks: [
                    'Woechtliche Schwarmkontrolle starten',
                    'Weiselzellen brechen oder Ableger bilden',
                    'Honigraum aufsetzen',
                    'Drohnenrahmen schneiden (Varroa)',
                ],
                tips: [
                    'Alle 7 Tage kontrollieren',
                    'Schwarmlust durch Raumgabe mindern',
                ],
            };
        }
        else if (adjustedWeek >= 21 && adjustedWeek <= 25) {
            focus[String(week)] = {
                title: 'Haupttracht',
                tasks: [
                    'Schwarmkontrolle fortsetzen',
                    'Honigräume erweitern',
                    'Wassergehalt pruefen',
                    'Drohnenrahmen schneiden',
                ],
                tips: [
                    'Bei Waldtracht auf Honigtautracht achten',
                    'Stockwaage taeglich ablesen',
                ],
            };
        }
        else if (adjustedWeek >= 26 && adjustedWeek <= 29) {
            focus[String(week)] = {
                title: 'Honigernte',
                tasks: [
                    'Honig schleudern',
                    'Bienenflucht einsetzen',
                    'Nach letzter Ernte sofort fuettern',
                    'Ameisensaeure-Behandlung vorbereiten',
                ],
                tips: [
                    'Wassergehalt unter 18% sicherstellen',
                    'Honig kuehlt und trocken lagern',
                ],
            };
        }
        else if (adjustedWeek >= 30 && adjustedWeek <= 35) {
            focus[String(week)] = {
                title: 'Varroabehandlung & Auffütterung',
                tasks: [
                    'Varroa-Behandlung durchfuehren (Ameisensaeure)',
                    'Auffuetterung starten (15-20kg Zucker pro Volk)',
                    'Weiselkontrolle',
                    'Varroa-Kontrolle (Gemülldiagnose)',
                ],
                tips: [
                    'Behandlung bei ueber 15 Grad Aussentemperatur',
                    'Fuetterung bis Mitte September abschliessen',
                ],
            };
        }
        else if (adjustedWeek >= 36 && adjustedWeek <= 40) {
            focus[String(week)] = {
                title: 'Einwinterung',
                tasks: [
                    'Futtervorrat kontrollieren (mind. 15kg)',
                    'Restentmilbung planen',
                    'Voelker einengen',
                    'Maeuseschutz anbringen',
                ],
                tips: [
                    'Starke Voelker ueberwintern besser',
                    'Schwache Voelker auflösen oder vereinigen',
                ],
            };
        }
        else if (adjustedWeek >= 41 && adjustedWeek <= 48) {
            focus[String(week)] = {
                title: 'Spätherbst - Winterruhe',
                tasks: [
                    'Restentmilbung mit Oxalsäure (bei Brutfreiheit)',
                    'Flugloch einengen',
                    'Stockwaage kontrollieren',
                ],
                tips: [
                    'Oxalsäure nur bei Brutfreiheit effektiv',
                    'Behandlung bei Temperaturen um 0 Grad',
                ],
            };
        }
        else {
            focus[String(week)] = {
                title: 'Winterruhe',
                tasks: [
                    'Flugloch kontrollieren',
                    'Stockwaage ablesen',
                    'Geraete pflegen und reparieren',
                ],
                tips: [
                    'Voelker nicht stoeren',
                    'Raehmchen draehten und Mittelwände einloeten',
                ],
            };
        }
    }
    return focus;
}
async function main() {
    console.log('Seeding database...');
    const zones = [
        { region: 'suedtirol', elevationBand: 'low', seasonStartMonth: 2, seasonStartDay: 15 },
        { region: 'suedtirol', elevationBand: 'mid', seasonStartMonth: 3, seasonStartDay: 1 },
        { region: 'suedtirol', elevationBand: 'high', seasonStartMonth: 3, seasonStartDay: 20 },
    ];
    for (const zone of zones) {
        await prisma.zoneProfile.upsert({
            where: {
                region_elevationBand: {
                    region: zone.region,
                    elevationBand: zone.elevationBand,
                },
            },
            update: {
                seasonStartMonth: zone.seasonStartMonth,
                seasonStartDay: zone.seasonStartDay,
                weeklyFocus: generateWeeklyFocus(zone.elevationBand),
            },
            create: {
                region: zone.region,
                elevationBand: zone.elevationBand,
                seasonStartMonth: zone.seasonStartMonth,
                seasonStartDay: zone.seasonStartDay,
                weeklyFocus: generateWeeklyFocus(zone.elevationBand),
            },
        });
        console.log(`  Zone profile: ${zone.region} / ${zone.elevationBand}`);
    }
    const passwordHash = await bcrypt.hash('demo1234', 12);
    const demoUser = await prisma.user.upsert({
        where: { email: 'demo@bee.app' },
        update: {},
        create: {
            email: 'demo@bee.app',
            passwordHash,
            displayName: 'Demo Imker',
            region: 'suedtirol',
            elevationBand: 'mid',
            language: 'de',
        },
    });
    console.log(`  Demo user: ${demoUser.email} (id: ${demoUser.id})`);
    const site1 = await prisma.site.upsert({
        where: { id: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d' },
        update: {},
        create: {
            id: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
            userId: demoUser.id,
            name: 'Bergstand Meran',
            location: 'Meran, Südtirol',
            latitude: 46.6713,
            longitude: 11.1535,
            elevation: 600,
            notes: 'Sonniger Standort, windgeschützt',
        },
    });
    console.log(`  Site: ${site1.name}`);
    const site2 = await prisma.site.upsert({
        where: { id: 'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e' },
        update: {},
        create: {
            id: 'b2c3d4e5-f6a7-4b8c-9d0e-1f2a3b4c5d6e',
            userId: demoUser.id,
            name: 'Talstand Bozen',
            location: 'Bozen, Südtirol',
            latitude: 46.4983,
            longitude: 11.3548,
            elevation: 260,
            notes: 'Nahe am Obstgarten',
        },
    });
    console.log(`  Site: ${site2.name}`);
    const hiveData = [
        { siteId: site1.id, number: 1, name: 'Carnica A', queenYear: 2024, queenColor: 'green', queenMarked: true },
        { siteId: site1.id, number: 2, name: 'Buckfast B', queenYear: 2023, queenColor: 'red', queenMarked: true },
        { siteId: site1.id, number: 3, name: 'Ableger 2025', queenYear: 2025, queenColor: 'blue', queenMarked: false },
        { siteId: site2.id, number: 1, name: 'Volk Tal-1', queenYear: 2024, queenColor: 'green', queenMarked: true },
        { siteId: site2.id, number: 2, name: 'Volk Tal-2', queenYear: 2023, queenColor: 'red', queenMarked: true },
        { siteId: site2.id, number: 3, name: 'Volk Tal-3', queenYear: 2024, queenColor: 'green', queenMarked: false },
    ];
    for (const hive of hiveData) {
        const created = await prisma.hive.create({
            data: {
                userId: demoUser.id,
                siteId: hive.siteId,
                number: hive.number,
                name: hive.name,
                queenYear: hive.queenYear,
                queenColor: hive.queenColor,
                queenMarked: hive.queenMarked,
            },
        });
        console.log(`  Hive: ${created.name} (site: ${hive.siteId === site1.id ? site1.name : site2.name})`);
    }
    console.log('Seeding complete!');
}
main()
    .catch((e) => {
    console.error('Seed error:', e);
    process.exit(1);
})
    .finally(async () => {
    await prisma.$disconnect();
});
//# sourceMappingURL=seed.js.map