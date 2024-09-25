const express = require('express');
const appService = require('./appService');

const router = express.Router();

// ----------------------------------------------------------
// API endpoints
// Modify or extend these routes based on your project's needs.
router.get('/check-db-connection', async (req, res) => {
    const isConnect = await appService.testOracleConnection();
    if (isConnect) {
        res.send('connected');
    } else {
        res.send('unable to connect');
    }
});

router.post('/get-attractions', async (req, res) => {
    const { province, city } = req.body;
    const tableContent = await appService.getAttractions(province, city);
    res.json({ data: tableContent });
});

router.post('/add-attraction', async (req, res) => {
    const { name, description, open, close, lat, long, category, province, city } = req.body;
    const tableContent = await appService.addAttraction(name, description, open, close, lat, long, category, province, city);
    res.json({ data: tableContent });
})

router.delete('/delete-attraction', async (req, res) => {
    const { attractionID } = req.body;
    const success = await appService.deleteAttraction(attractionID);
    if (success) {
        res.status(200).json({ success: true });
    } else {
        res.status(500).json({ success: false });
    }
})

router.post('/update-attraction', async (req, res) => {
    const { attractionID, name, description, open, close, lat, long, category, province, city } = req.body;
    const tableContent = await appService.updateAttraction(attractionID, name, description, open, close, lat, long, category, province, city);
    res.json({ data: tableContent });
})

router.get('/avg-attractions-per-province', async (req, res) => {
    try {
        const result = await appService.getAvgAttractionsPerProvince();
        if (result !== null && result !== undefined) {
            res.json({ success: true, data: result });
        } else {
            res.status(500).json({ success: false, error: 'Failed to get average attractions per province' });
        }
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/count-attractions', async (req, res) => {
    const { province, city } = req.body;

    const count = await appService.countAttractionsByCityAndProvince(province, city);
    if (count !== null && count !== undefined) {
        res.json({ success: true, count: count });
    } else {
        res.status(500).json({ success: false, error: 'Failed to count attractions' });
    }
});

router.post('/count-attractions-having', async (req, res) => {

    const result = await appService.countAttractionsHaving();
    res.json(result);

});

router.post("/project-tables", async (req, res) => {
    const { attractionID, selectedBoxes } = req.body;
    try {
        const projectedExperiences = await appService.projectExperienceAttributes(attractionID, selectedBoxes);

        if (projectedExperiences) {
            res.json({ projectedExperiences });
        } else {
            res.status(400).json({ success: false });
        }
    } catch (error) {
        res.status(400).json({ success: false });
    }
});


router.post("/filter-experiences", async (req, res) => {
    const { price, comparison } = req.body;
    try {
        const filteredExperiences = await appService.applyPriceFilters(price, comparison);

        if (filteredExperiences) {
            res.json({ filteredExperiences });
        } else {
            res.status(400).json({ success: false });
        }
    } catch (error) {
        res.status(400).json({ success: false });
    }
})

router.post("/find-completionists", async (req, res) => {
    const { attractionID } = req.body;
    const tableContent = await appService.findCompletionist(attractionID);
    if (tableContent[0]) {
        res.status(200).json({ success: true, data: tableContent });
    } else {
        res.status(400).json({ success: false });
    }
});



module.exports = router;